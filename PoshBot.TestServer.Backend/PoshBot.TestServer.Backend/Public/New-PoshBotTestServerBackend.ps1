
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
        PS C:\> $config = @{Name = 'TestServer'; Token = '<API-TOKEN>'}
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
        foreach ($item in $Configuration) {
            if (-not $item.Token) {
                throw 'Configuration is missing [Token] parameter'
            } else {
                Write-Verbose 'Creating new TestServer backend instance'

                # Note that [token] is just an example
                # In a real backend plugin, you would pass any
                # needed information from $Configuration to
                # the constructor
                $backend = [TestServerBackend]::new($item.Token)
                if ($item.Name) {
                    $backend.Name = $item.Name
                }
                $backend
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTestServerBackend'
