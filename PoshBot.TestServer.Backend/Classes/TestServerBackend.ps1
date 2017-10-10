
class TestServerBackend : Backend {
  [hashtable]$UserList

  # Constructor
  TestServerBackend () {
    Write-Warning "TestServerBackend:initialize"
    $conn = [TestServerConnection]::New()
    $this.Connection = $conn
    # Implement any needed initialization steps
    $this.UserList = @{}
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

    $stream = $this.Connection.TcpClient.GetStream()
    
    $Message = "~M{0}{1}{2}" -f 'Zorg', "~~", ($Response.Text -join "`n")
    $data = [text.Encoding]::Ascii.GetBytes($Message)
    $stream.Write($data,0,$data.length)
    $stream.Flush()

  }

  # Return a user object given an Id
  [Person]GetUser([string]$UserId) {
    Write-Warning "TestServerBackend:getuser $($UserId)"

    $Person = $null
    if ($UserId -eq '0') {
      $Person = [Person]::New()
      $Person.Id = $UserId
      $Person.ClientId = $UserId
      $Person.NickName = 'Zorg'
      $person.FirstName = 'Zorg'
      $Person.LastName = ''
      $Person.FullName = 'Zorg'
    } else {
      $Person = [Person]::New()
      $Person.Id = $UserId
      $Person.ClientId = $UserId
      $Person.NickName = 'Human'
      $person.FirstName = 'Human'
      $Person.LastName = ''
      $Person.FullName = 'Human'
    }

    # Return a [Person] instance (or a class derived from [Person])
    return $Person
  }

  # Resolve a user name to user id
  [string]UsernameToUserId([string]$Username) {
    Write-Warning "TestServerBackend:UsernameToUserId $($Username)"
    # Do something using the chat network APIs to
    # resolve a username to an Id and return it
    # TODO FAKED!
    if ($Username -eq 'Zorg') {
      return '0'
    } else {
      return '1'
    }
  }

  # Resolve a user ID to a username/nickname
  [string]UserIdToUsername([string]$UserId) {
    Write-Warning "TestServerBackend:UserIDToUsername $($UserId)"
    # Do something using the network APIs to
    # resolve a username from an Id and return it

    if ($UserId -eq '0') {
      return 'Zorg'
    } else {
      return 'Human'
    }
  }
}
