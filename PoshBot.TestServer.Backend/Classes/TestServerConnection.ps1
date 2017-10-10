
class TestServerConnection : Connection {
  [Net.Sockets.TCPClient]$TcpClient
  [System.Collections.Queue]$MessageQueue
  [bool]$Connected

  hidden [Object]$ConnectionJob

  TestServerConnection() {
    # Implement any needed initialization steps
    $this.TcpClient = $null
    $this.Connected = $false
    $this.MessageQueue =  [System.Collections.Queue]::Synchronized((New-Object System.collections.queue))
  }

  # Connect to the chat network
  [void]Connect() {
    Write-Warning "TestServerConnection:connect"

    # Use the configuration stored in $this.Config (inherited from base class)
    # to connect to the chat network
    $botName = 'Zorg'
    $localPort = 15600

    #Connect to server
    $Endpoint = new-object System.Net.IPEndpoint ([ipaddress]::any,0)
    $this.TcpClient = [Net.Sockets.TCPClient]$endpoint
    Try {
      $this.TcpClient.Connect('127.0.0.1',$localPort)
      $ServerStream = $this.TcpClient.GetStream()
      $data = [text.Encoding]::Ascii.GetBytes($botName)
      $ServerStream.Write($data,0,$data.length)
      $ServerStream.Flush()
      If ($this.TcpClient.Connected) {
        $this.Connected = $true
        #Kick off a job to watch for messages from clients
        $newRunspace = [RunSpaceFactory]::CreateRunspace()
        $newRunspace.Open()
        $newRunspace.SessionStateProxy.setVariable("TcpClient", $this.TcpClient)
        $newRunspace.SessionStateProxy.setVariable("MessageQueue", $this.MessageQueue)
        $newPowerShell = [PowerShell]::Create()
        $newPowerShell.Runspace = $newRunspace
        $sb = {
          # Code to kick off client connection monitor and look for incoming messages.
          $serverstream = $TcpClient.GetStream()
          # While client is connected to server, check for incoming traffic
          While ($TcpClient.Connected) {
            Try {
              [byte[]]$inStream = New-Object byte[] 200KB
              $buffSize = $TcpClient.ReceiveBufferSize
              $return = $serverstream.Read($inStream, 0, $buffSize)
              If ($return -gt 0) {
                $Messagequeue.Enqueue([System.Text.Encoding]::ASCII.GetString($inStream[0..($return - 1)]))
              }
            } Catch {
              #Connection to server has been closed
              $Messagequeue.Enqueue("~S")
              Break
            }
          }
          #Shutdown the connection as connection has ended
          $TcpClient.Client.Disconnect($True)
          $TcpClient.Client.Close()
          $TcpClient.Close()
        }
        $job = "" | Select Job, PowerShell
        $job.PowerShell = $newPowerShell
        $Job.job = $newPowerShell.AddScript($sb).BeginInvoke()
        $this.ConnectionJob = $job
      }
    } Catch {
      #Errors Connecting to server
      $this.TcpClient.Close()
      $this.ConnectionJob.PowerShell.EndInvoke($this.ConnectionJob)
      Write-Warning "TestServerConnection:connect $_"
    }
  }

  # Disconnect from the chat network
  [void]Disconnect() {
    Write-Warning "TestServerConnection:disconnect"
    # Use the configuration stored in $this.Config (inherited from base class)
    # to disconnect to the chat network
    $this.TcpClient.Close()
    $this.ConnectionJob.PowerShell.EndInvoke($this.ConnectionJob.Job)
    $this.ConnectionJob.PowerShell.Runspace.Close()
    $this.ConnectionJob.PowerShell.Dispose()
    $this.Connected = $false
  }
}
