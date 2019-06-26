#Requires -Modules Pester

using namespace System.IO

[string]$DirectorySeparator = [Path]::DirectorySeparatorChar
[string]$TempDirectory = "$PSScriptRoot${DirectorySeparator}temp"
[string]$IgnoreFileName = '.ignore'

. "$PSScriptRoot/../src/Public/Get-FilteredChildItem.ps1"

Describe 'Get-FilteredChildItem' {
    BeforeEach {
        if(Test-Path -Path $TempDirectory)
        {
            Remove-Item -Path $TempDirectory -Recurse -Force
        }
        $null = New-Item -ItemType Directory -Path $TempDirectory
    }

    AfterAll {
        if(Test-Path -Path $TempDirectory)
        {
            Remove-Item -Path $TempDirectory -Recurse -Force
        }
    }

    It 'Does not exclude any files if there are no ignore files.' {
        In $TempDirectory {
            New-Item -ItemType File -Name 'test1'
            New-Item -ItemType File -Name 'test2'
        }

        Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1', 'test2'
    }

    It 'Does not exclude any files if the ignore file is empty, except the ignore file.' {
        In $TempDirectory {
            New-Item -ItemType File -Name 'test1'
            New-Item -ItemType File -Name 'test2'
            New-Item -ItemType File -Name $IgnoreFileName
        }

        Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1', 'test2'
    }

    It 'Does not exclude any files if the ignore file is empty and -IncludeIgnoreFiles is provided.' {
        In $TempDirectory {
            New-Item -ItemType File -Name 'test1'
            New-Item -ItemType File -Name 'test2'
            New-Item -ItemType File -Name $IgnoreFileName
        }

        Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName -IncludeIgnoreFiles | Should -Be (Get-ChildItem -Path $TempDirectory -Force | Select-Object -ExpandProperty Name)
    }

    It 'Does not exclude any files if there are no matching files.' {
        In $TempDirectory {
            New-Item -ItemType File -Name 'test1'
            New-Item -ItemType File -Name 'test2'
            New-Item -ItemType File -Name $IgnoreFileName -Value 'test'
        }

        Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1', 'test2'
    }

    It 'Ignores comments and blank lines' {
        In $TempDirectory {
            New-Item -ItemType File -Name 'test1'
            New-Item -ItemType File -Name 'test2'
            New-Item -ItemType File -Name $IgnoreFileName -Value @'
# test1
#test1

# test2
#test2
'@
        }

        Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1', 'test2'
    }

    Context 'Excludes one file' {
        It 'Excludes one file' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1'
                New-Item -ItemType File -Name 'test2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test1'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test2'
        }

        It 'Excludes one file in a subdirectory by general pattern' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test1'
                In (New-Item -ItemType Directory -Name 'temp') {
                    New-Item -ItemType File -Name 'test1'
                }
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test2'
        }

        It 'Excludes one file in a subdirectory by immediate pattern' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1'
                New-Item -ItemType File -Name 'test2'
                New-Item -ItemType File -Name $IgnoreFileName -Value '/temp/test1'
                In (New-Item -ItemType Directory -Name 'temp') {
                    New-Item -ItemType File -Name 'test1'
                }
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Select-Object -ExpandProperty FullName | Should -Be "${TempDirectory}${DirectorySeparator}test1", "${TempDirectory}${DirectorySeparator}test2"
        }

        It 'Excludes one file in the immediate directory' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1'
                New-Item -ItemType File -Name 'test2'
                New-Item -ItemType File -Name $IgnoreFileName -Value '/test1'
                In (New-Item -ItemType Directory -Name 'temp') {
                    New-Item -ItemType File -Name 'test1'
                }
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Select-Object -ExpandProperty FullName | Should -Be "${TempDirectory}${DirectorySeparator}test2", "${TempDirectory}${DirectorySeparator}temp${DirectorySeparator}test1"
        }
    }

    Context 'Wildcards' {
        It 'Matches any one character' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test?-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test-file1', 'test-file2'
        }

        It 'Matches more than one single-character wildcard' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test-file'
                New-Item -ItemType File -Name 'task-file'
                New-Item -ItemType File -Name 'tes-file'
                New-Item -ItemType File -Name $IgnoreFileName -Value 't???-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'tes-file'
        }

        It 'Matches a set of characters' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test3-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test[12]-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test-file1', 'test-file2', 'test3-file'
        }

        It 'Matches a range of characters' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test3-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test[0-9]-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test-file1', 'test-file2'
        }

        It 'Does not match a set of characters' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test3-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test[!3-]-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test-file1', 'test-file2', 'test3-file'
        }

        It 'Does not match a range of characters' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test3-file'
                New-Item -ItemType File -Name 'test4-file'
                New-Item -ItemType File -Name 'test5-file'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test[!2-4]-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test2-file', 'test3-file', 'test4-file'
        }

        It 'Matches any number of characters at the end of a file name' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test-file*'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1-file', 'test2-file'
        }

        It 'Matches any number of characters at the end of a file name' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test-file'
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test12345-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name 'test-file12345'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test-file*'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test1-file', 'test12345-file', 'test2-file'
        }

        It 'Matches any number of characters in the middle of a file name' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'test-file'
                New-Item -ItemType File -Name 'test1-file'
                New-Item -ItemType File -Name 'test2-file'
                New-Item -ItemType File -Name 'test12345-file'
                New-Item -ItemType File -Name 'test-file1'
                New-Item -ItemType File -Name 'test-file2'
                New-Item -ItemType File -Name 'test-file12345'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test*-file'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Should -Be 'test-file1', 'test-file12345', 'test-file2'
        }

        It 'Matches globstars' {
            In $TempDirectory {
                In (New-Item -ItemType Directory -Name 'test1') {
                    In (New-Item -ItemType Directory -Name 'test2') {
                        New-Item -ItemType File -Name 'test'
                        New-Item -ItemType File -Name 'potato'
                    }
                    In (New-Item -ItemType Directory -Name 'test3') {
                        New-Item -ItemType File -Name 'test'
                        New-Item -ItemType File -Name 'potato'
                    }
                }
                In (New-Item -ItemType Directory -Name 'task') {
                    New-Item -ItemType File -Name 'test'
                }
                New-Item -ItemType File -Name $IgnoreFileName -Value 'test*/**/test'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Select-Object -ExpandProperty FullName | Should -Be "${TempDirectory}${DirectorySeparator}task${DirectorySeparator}test", "${TempDirectory}${DirectorySeparator}test1${DirectorySeparator}test2${DirectorySeparator}potato", "${TempDirectory}${DirectorySeparator}test1${DirectorySeparator}test3${DirectorySeparator}potato"
        }
    }

    Context 'Directories' {
        It 'Excludes directories, but not files with the same name' {
            In $TempDirectory {
                In (New-Item -ItemType Directory -Name 'test') {
                    New-Item -ItemType File -Name 'potato'
                }
                In (New-Item -ItemType Directory -Name 'potato') {
                    New-Item -ItemType File -Name 'test'
                }
                In (New-Item -ItemType Directory -Name 'inner') {
                    In (New-Item -ItemType Directory -Name 'test') {
                        New-Item -ItemType File -Name 'potato'
                    }
                    In (New-Item -ItemType Directory -Name 'potato') {
                        New-Item -ItemType File -Name 'test'
                    }
                }
                New-Item -ItemType File -Name $IgnoreFileName -Value 'potato/'
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Select-Object -ExpandProperty FullName | Should -Be "${TempDirectory}${DirectorySeparator}inner${DirectorySeparator}test${DirectorySeparator}potato", "${TempDirectory}${DirectorySeparator}test${DirectorySeparator}potato"
        }
    }

    Context 'Multiple ignore files' {
        It 'Ignores files defined in a nested ignore file only in that ignore file''s context' {
            In $TempDirectory {
                New-Item -ItemType File -Name 'ignore-me'
                New-Item -ItemType File -Name 'not-me'
                New-Item -ItemType File -Name $IgnoreFileName -Value 'ignore-me'
                In (New-Item -ItemType Directory -Name 'inner') {
                    New-Item -ItemType File -Name $IgnoreFileName -Value 'potato'
                    In (New-Item -ItemType Directory -Name 'test') {
                        New-Item -ItemType File -Name 'potato'
                    }
                    In (New-Item -ItemType Directory -Name 'potato') {
                        New-Item -ItemType File -Name 'test'
                        New-Item -ItemType File -Name 'ignore-me'
                    }
                }
                In (New-Item -ItemType Directory -Name 'inner2') {
                    In (New-Item -ItemType Directory -Name 'test') {
                        New-Item -ItemType File -Name 'potato'
                    }
                    In (New-Item -ItemType Directory -Name 'potato') {
                        New-Item -ItemType File -Name $IgnoreFileName -Value 'test'
                        New-Item -ItemType File -Name 'test'
                        New-Item -ItemType File -Name 'ignore-me'
                    }
                    New-Item -ItemType File -Name 'test-file'
                }
            }

            Get-FilteredChildItem -Path $TempDirectory -IgnoreFileName $IgnoreFileName | Select-Object -ExpandProperty FullName | Should -Be "${TempDirectory}${DirectorySeparator}not-me", "${TempDirectory}${DirectorySeparator}inner2${DirectorySeparator}test-file", "${TempDirectory}${DirectorySeparator}inner2${DirectorySeparator}test${DirectorySeparator}potato"
        }
    }
}
