
class TestServerBackend : Backend {

  # Constructor
  TestServerBackend () {
    Write-Warning "TestServerBackend:initialize"
    # Implement any needed initialization steps
  }

  # Connect to the chat network
  [void]Connect() {
    Write-Warning "TestServerBackend:Connect"
    # Include logic to connect to the chat network

    # The actual logic to connect to the chat network
    # should be in the [Connection] object
    $this.Connection.Connect()
  }

  # Disconnect from the chat network
  [void]Disconnect() {
    Write-Warning "TestServerBackend:Disconnect"
    # Include logic to disconnect to the chat network

    # The actual logic to disconnect to the chat network
    # should be in the [Connection] object
    $this.Connection.Disconnect()
  }

  # Send a ping on the chat network
  [void]Ping() {
    Write-Warning "TestServerBackend:ping"
    # Only implement this method to send a message back
    # to the chat network to keep the connection open

    # If N/A, you don't need to implement this
  }

  # Receive a message from the chat network
  [Message]ReceiveMessage() {
    Write-Warning "TestServerBackend:RXmessage"
    # Implement logic to receive a message from the
    # chat network using network-specific APIs.

    # This method assumes that a connection to the chat network
    # has already been made using $this.Connect()

    # This method should return quickly (no blocking calls)
    # so PoshBot can continue in its message processing loop
    return $null
  }

  # Send a message back to the chat network
  [void]SendMessage([Response]$Response) {
    Write-Warning "TestServerBackend:sendmessage"
    # Implement logic to send a message
    # back to the chat network
  }

  # Return a user object given an Id
  [Person]GetUser([string]$UserId) {
    Write-Warning "TestServerBackend:getuser"
    # Return a [Person] instance (or a class derived from [Person])
    return $null
  }

  # Resolve a user name to user id
  [string]UsernameToUserId([string]$Username) {
    Write-Warning "TestServerBackend:UsernameToUserId"
    # Do something using the chat network APIs to
    # resolve a username to an Id and return it
    return '12345'
  }

  # Resolve a user ID to a username/nickname
  [string]UserIdToUsername([string]$UserId) {
    Write-Warning "TestServerBackend:UserIDToUsername"
    # Do something using the network APIs to
    # resolve a username from an Id and return it
    return 'JoeUser'
  }
}
