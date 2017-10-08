
function New-PoshBotTestServerBackend {
  <#
  .SYNOPSIS
    Creates a new instance of the TestServer PoshBot backend class.
  .DESCRIPTION
    Creates a new instance of the TestServer PoshBot backend class.
  .PARAMETER Configuration
    Hashtable of required properties needed by the backend to initialize and
    connect to the backend chat network.
  .EXAMPLE
    PS C:\> $config = @{Name = 'TestServerBackend'; Token = '<API-TOKEN>'}
    PS C:\> $backend = New-PoshBotTestServerBackend -Configuration $config

    Create a hashtable containing required properties for the backend
    and create a new backend instance from them
  .INPUTS
    hashtable
  .OUTPUTS
    TestServerBackend
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
  [cmdletbinding()]
  param(
    [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('BackendConfiguration')]
    [hashtable[]]$Configuration
  )

  process {
    # Sanity Checks

    # if ($Configuration.Username -eq $null) { throw 'Configuration is missing [Username] parameter' }
    # if ($Configuration.Password -eq $null) { throw 'Configuration is missing [Password] parameter' }
    # if ($Configuration.DLLPath -eq $null) { throw 'Configuration is missing [DLLPath] parameter' }

    # Create the Test Server Backend
    $backend = [TestServerBackend]::new() # $Configuration.Username, $Configuration.Password, $Configuration.DLLPath)
    if ($Configuration.Name) {
      $backend.Name = $Configuration.Name
    }

    $backend
  }
}

Export-ModuleMember -Function 'New-PoshBotTestServerBackend'
