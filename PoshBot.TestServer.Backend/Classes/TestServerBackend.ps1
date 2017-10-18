
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

    # TODO should be configurable
    $this.BotId = 'Zorg' #$this.GetBotIdentity()
  }

  # Disconnect from the chat network
  [void]Disconnect() {
    Write-Warning "TestServerBackend:Disconnect"
    # Include logic to disconnect to the chat network

    # The actual logic to disconnect to the chat network
    # should be in the [Connection] object
    $this.Connection.Disconnect()
  }

  # Add a reaction to an existing chat message
  [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
    write-warning "Add reaction to message $($Message.Id)"
    # ~A<Username>~~MsgID~~<ReactionType>
    $OutboundMessage = "~A$($this.BotId)~~$($Message.ID)~~$($Type.ToString())"
    $data = [text.Encoding]::Ascii.GetBytes($OutboundMessage)
    $stream = $this.Connection.TcpClient.GetStream()
    $stream.Write($data,0,$data.length)
    $stream.Flush()
  }

  # Add a reaction to an existing chat message
  [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
    write-warning "Remove reaction to message $($Message.Id)"
    # ~R<Username>~~MsgID~~<ReactionType>
    $OutboundMessage = "~R$($this.BotId)~~$($Message.ID)~~$($Type.ToString())"
    $data = [text.Encoding]::Ascii.GetBytes($OutboundMessage)
    $stream = $this.Connection.TcpClient.GetStream()
    $stream.Write($data,0,$data.length)
    $stream.Flush()
  }

  # Send a ping on the chat network
  # [void]Ping() {
  #   Write-Warning "TestServerBackend:ping"
  #   # Only implement this method to send a message back
  #   # to the chat network to keep the connection open

  #   # If N/A, you don't need to implement this
  # }

  # Receive a message from the chat network
  [Message[]]ReceiveMessage() {
    #Write-Warning "TestServerBackend:RXmessage"
    $msgOut = $null
    $messages = New-Object -TypeName System.Collections.ArrayList

    while ($this.Connection.MessageAvailable()) {
      $rawMessage = $this.Connection.GetNextMessage()
      write-warning "Raw messages is $rawMessage"
      $MessageID = $null
      if ($rawMessage.StartsWith("!")) {
        # The message has an ID. Extract it and send the message on for parsing.
        $rawMessage = $rawMessage.Substring(1)
        $MessageID = $rawMessage.Substring(0,32)
        $rawMessage = $rawMessage.SubString(32 + 1)
      }

      $msgOut = [Message]::new()
      $msgOut.Id = $MessageID
      $msgOut.RawMessage = $rawMessage
      $msgOut.From = $null
      
      Switch ($rawMessage) {
        # {$_.Startswith("~B")} {
        #   # Direct Message
        #   $data = ($_).SubString(2)
        #   $split = $data -split ("{0}" -f "~~")
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Orange))
        # }
        # {$_.Startswith("~I")} {
        #   # Message
        #   $data = ($_).SubString(2)
        #   $split = $data -split ("{0}" -f "~~")
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
        #   $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Blue))
        # }
        {$_.Startswith("~M")} {
          # Channel Message
          $data = ($_).SubString(2)
          $msgArgs = $data -split ("{0}" -f "~~")

          $msgOut.Type = [MessageType]::Message
          $msgOut.From = $msgArgs[0] # TODO Should be using IDs not names here
          $msgOut.FromName = $msgArgs[0]
          $msgOut.To = '-1' # Only one channel at the moment
          $msgOut.ToName = 'Lobby' # Only one channel at the moment
          $msgOut.Text = $msgArgs[1]
          
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Black))
        }
        {$_.Startswith("~D")} {
          # Disconnect
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} has disconnected from the server" -f $_.SubString(2)) -ForeGround Green))
          # # Remove user from online list
          # $OnlineUsers.Items.Remove($_.SubString(2))
        }
        {$_.StartsWith("~C")} {
          # Connect
          # $Message = ("{0} has connected to the server" -f $_.SubString(2))
          # $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
          # $Paragraph.Inlines.Add((New-ChatMessage -Message $message -ForeGround Green))
          # ##Add user to online list
          # If ($Username -ne $_.SubString(2)) {
          #   $OnlineUsers.Items.Add($_.SubString(2))
          # }
        }
        {$_.StartsWith("~S")} {
          #Server Shutdown
        }
        {$_.StartsWith("~Z")} {
          # List of connected users
          # $online = (($_).SubString(2) -split "~~")
          # #Add online users to window
          # $Online | ForEach {
          #   $OnlineUsers.Items.Add($_)
          # }
        }
        Default {
        }
      }

      # Ignore messages from ourselves
      if ($msgOut.From -eq $this.Connection.ThisBotID()) {
        $msgOut.From = $null
      }

      if ($msgOut.From -ne $null) { $messages.Add($msgOut) | Out-Null }
    }
    # Implement logic to receive a message from the
    # chat network using network-specific APIs.

    # This method assumes that a connection to the chat network
    # has already been made using $this.Connect()

    # This method should return quickly (no blocking calls)
    # so PoshBot can continue in its message processing loop
    return $messages
  }

  # Send a message back to the chat network
  [void]SendMessage([Response]$Response) {
    Write-Warning "TestServerBackend:sendmessage $($Response.Text)"

    # Implement logic to send a message
    # back to the chat network

    $stream = $this.Connection.TcpClient.GetStream()

    foreach ($customResponse in $Response.Data) {

      [string]$sendTo = $Response.To
      # TODO Direct Messages
      # if ($customResponse.DM) {
      #   $sendTo = "@$($this.UserIdToUsername($Response.MessageFrom))"
      # }      

      $messageText = ''
      switch -Regex ($customResponse.PSObject.TypeNames[0]) {
        '(.*?)PoshBot\.Card\.Response' {
Write-Warning 'Custom response is [PoshBot.Card.Response]'
          $this.LogDebug('Custom response is [PoshBot.Card.Response]')
          $messageText = $customResponse.Text
          break
        }
        '(.*?)PoshBot\.Text\.Response' {
Write-Warning 'Custom response is [PoshBot.Text.Response]'
          $this.LogDebug('Custom response is [PoshBot.Text.Response]')
          $messageText = $customResponse.Text
          break
        }
        '(.*?)PoshBot\.File\.Upload' {
Write-Warning '(.*?)PoshBot\.File\.Upload'
          $this.LogDebug('Custom response is [PoshBot.File.Upload]')
          $messageText = $customResponse.Text
          break
        }
      }

      $Message = "~M{0}{1}{2}" -f ($this.BotId), "~~", ($messageText)
      $data = [text.Encoding]::Ascii.GetBytes($Message)
      $stream.Write($data,0,$data.length)
      $stream.Flush()
    }

    if ($Response.Text.Count -gt 0) {
      foreach ($t in $Response.Text) {
        $this.LogDebug("Sending response back to channel [$($Response.To)]", $t)
        $Message = "~M{0}{1}{2}" -f ($this.BotId), "~~", ($t)
        $data = [text.Encoding]::Ascii.GetBytes($Message)
        $stream.Write($data,0,$data.length)
        $stream.Flush()
      }
    }
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
