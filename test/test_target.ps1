Invoke-Pester ./test/functions/initialize.Test.ps1 -Output Detailed -Tag 'Target'
Invoke-Pester ./test/functions/common_functions.Test.ps1 -Output Detailed -Tag 'Target'
Invoke-Pester ./test/functions/tver_functions.Test.ps1 -Output Detailed -Tag 'Target'
Invoke-Pester ./test/functions/tverrec_functions.Test.ps1 -Output Detailed -Tag 'Target'
