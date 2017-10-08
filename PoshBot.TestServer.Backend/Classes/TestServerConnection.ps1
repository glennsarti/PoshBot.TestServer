
class TestServerConnection : Connection {

  TestServerConnection() {
      # Implement any needed initialization steps
  }

  # Connect to the chat network
  [void]Connect() {
    Write-Warning "TestServerConnection:connect"
    
    # Use the configuration stored in $this.Config (inherited from base class)
    # to connect to the chat network
  }

  # Disconnect from the chat network
  [void]Disconnect() {
    Write-Warning "TestServerConnection:disconnect"
    # Use the configuration stored in $this.Config (inherited from base class)
    # to disconnect to the chat network
  }
}
