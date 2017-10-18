Function Invoke-PostBotTestServerClient {
  [cmdletbinding()]
  Param (
    [parameter()]
    [string]$EnableLogging # (Join-Path $pwd ChatLog.log)
  )

  Process {
    $rs=[RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()
    $ps = [PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.Runspace.SessionStateProxy.SetVariable("pwd",$pwd)

    $handle = $ps.AddScript({
      Add-Type assemblyName PresentationFramework
      Add-Type assemblyName PresentationCore
      Add-Type assemblyName WindowsBase
      ##Functions
      Function Script:Save-Transcript {
          $saveFile = New-Object Microsoft.Win32.SaveFileDialog
          $saveFile.Filter = "Text documents (.txt)|*.txt"
          $saveFile.DefaultExt = '.txt'
          $saveFile.FileName = ("{0:yyyyddmm_hhmmss}ChatTranscript" -f (Get-Date))
          $saveFile.OverwritePrompt = $True
          $return = $saveFile.ShowDialog()
          If ($return) {
              $Message = new-object System.Windows.Documents.TextRange -ArgumentList $MainMessage.Document.ContentStart,$MainMessage.Document.ContentEnd
              $Message.text | Out-File $saveFile.FileName
          }
      }
      Function Script:New-ChatMessage {
        [cmdletbinding()]
        Param (
          [parameter(ValueFromPipeLine=$True)]
          [string]$Message,
          [parameter()]
          [string]$Foreground,
          [parameter()]
          [string]$Background,
          [parameter()]
          [switch]$Bold
        )
        Begin {
          $Run = New-Object System.Windows.Documents.Run
          $Run.Foreground = $Foreground
          If ($PSBoundParameters['Bold']) {
            $run.FontWeight = 'Bold'
          }
        }
        Process {
          $Run.Text = $Message
        }
        End{
          Write-Output $Run
        }
      }

      [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
      [xml]$xaml = @"
<!--<Window x:Class="WpfApp1.MainWindow"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
      xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
      xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
      xmlns:local="clr-namespace:WpfApp1"
      mc:Ignorable="d"
      Title="MainWindow" Height="350" Width="525">
  <Grid>
      
  </Grid>
</Window>-->

<Window
  xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
  xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
  x:Name="Window" Title="PoshChat" Height="400" Width="550" WindowStartupLocation="CenterScreen" ShowInTaskbar="True"
  Background="{DynamicResource {x:Static SystemColors.ControlBrushKey}}">

<Window.Resources>
  <XmlDataProvider x:Key="SubjectList" XPath="subjects" x:Name="xmlSubjectList">
    <x:XData>
      <subjects xmlns="">
        <subject name="Lobby" subjecttype="room" id="-1" />
        <subject name="Zorg" subjecttype="room" id="-1" />
        <subject name="AReallyReallyReallyLongName" subjecttype="room" id="-1" />
      </subjects>
    </x:XData>
  </XmlDataProvider>

  <XmlDataProvider x:Key="Messages" XPath="messages" x:Name="xmlMessages">
    <x:XData>
      <messages xmlns="">
        <message timestamp="20170101 23:00:00" from="Zorg" id="1234">Hello1<reaction type="gears" count="1"/>

        </message>
        <message timestamp="20170101 23:01:00" from="Zorg" id="5678">Hello2<reaction type="exclaimation" count="2"/>
        </message>
      </messages>
    </x:XData>
  </XmlDataProvider>

</Window.Resources>

<DockPanel >
  <Grid DockPanel.Dock="Top">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="Auto"/>
      <ColumnDefinition Width="5" />
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="5" />
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <ScrollViewer Grid.Column="0" Grid.Row="0"
      VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Background="{DynamicResource {x:Static SystemColors.ControlBrushKey}}">
      <ItemsControl x:Name="SubjectList" DataContext="{DynamicResource SubjectList}" ItemsSource="{Binding XPath=subject}">
        <ItemsControl.ItemTemplate>
          <DataTemplate>
            <!-- User/Room List -->
            <Border
              Margin="2" Padding="2"
              BorderBrush="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}"
              BorderThickness="1">

              <TextBlock Padding="1" TextWrapping="Wrap" Text="{Binding XPath=@name}"/>
            </Border>

          </DataTemplate>
        </ItemsControl.ItemTemplate>
      </ItemsControl>
    </ScrollViewer>

    <GridSplitter Width="5" Grid.Column='1' Grid.Row="0" Grid.RowSpan="3" Background="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" />

    <ScrollViewer Grid.Column='2' Grid.Row="0" Visibility="Visible"
      VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Background="{DynamicResource {x:Static SystemColors.ControlBrushKey}}">
      <ItemsControl x:Name="MessageList" DataContext="{DynamicResource Messages}" ItemsSource="{Binding XPath=message}">
        <ItemsControl.ItemTemplate>
          <DataTemplate>
            <!--Messages List-->
            <Border BorderThickness="0 0 0 1" VerticalAlignment="Top" BorderBrush="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <!-- TODO Add profile picture -->
                <Rectangle Width="50" Height="50" Fill="Blue" VerticalAlignment="Top" Visibility="Hidden" />

                <Grid Grid.Column="1">
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                  </Grid.RowDefinitions>

                  <StackPanel Orientation="Horizontal" Grid.Row="0">
                    <Label Padding="5,1,5,1" Content="{Binding XPath=@from}" FontWeight="Bold"/>
                    <Label Padding="5,1,5,1" Content="{Binding XPath=@timestamp}" />
                  </StackPanel>

                  <TextBlock Padding="5,1,5,1" Grid.Row="1" TextWrapping="Wrap" Text="{Binding XPath=.}"/>

                  <ItemsControl ItemsSource="{Binding XPath=reaction}" Grid.Row="2" HorizontalAlignment="Left" VerticalAlignment="Top">
                    <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Border Padding="1" Margin="2" BorderThickness="1"  BorderBrush="{DynamicResource {x:Static SystemColors.ControlLightBrushKey}}">
                          <Image Width="16" Height="16" Margin="1" Source="{Binding XPath=@url}" ToolTip="{Binding XPath=@count}" />
                        </Border>
                      </DataTemplate>
                    </ItemsControl.ItemTemplate>
                  </ItemsControl>
                </Grid>
              </Grid>
            </Border>
          </DataTemplate>
        </ItemsControl.ItemTemplate>
      </ItemsControl>
    </ScrollViewer>


    <!-- Row 1 -->
    <GridSplitter Height="5" Grid.Row='1' Grid.Column="1" HorizontalAlignment="Stretch" Grid.ColumnSpan="2" Background="{DynamicResource {x:Static SystemColors.ControlDarkBrushKey}}" />

    <!-- Row 2 -->
    <Grid Grid.Column = '0' Grid.Row = '2' ShowGridLines = 'false' MinHeight="20" MinWidth="20">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width ='Auto'></ColumnDefinition>
        <ColumnDefinition Width ='*'></ColumnDefinition>
      </Grid.ColumnDefinitions>
      <Grid.RowDefinitions>
        <RowDefinition Height = 'Auto'/>
        <RowDefinition Height = '*'/>
      </Grid.RowDefinitions>
      <Label Padding="2" Margin="2" Content = 'UserName' HorizontalAlignment = 'Stretch' Grid.Column = '0' Grid.Row = '0'/>
      <TextBox Padding="2" Margin="2" x:Name = 'username_txt' HorizontalAlignment = 'Stretch' Grid.Column = '2' Grid.Row = '0' Text = 'Human' VerticalAlignment="Center" />
      <Button Padding="2" Margin="2" x:Name = 'Connect_btn' MaxWidth = '75' Height = '20' Content = 'Connect'
                  Grid.Column = '0' Grid.Row = '1' HorizontalAlignment = 'stretch'/>
      <Button Padding="2" Margin="2" x:Name = 'Disconnect_btn' MaxWidth = '75' Height = '20' Content = 'Disconnect'
                  Grid.Column = '2' Grid.Row = '1' HorizontalAlignment = 'stretch' IsEnabled = 'False'/>
      <Label Grid.Column = '3' Grid.Row = '2' Width ='5'/>
    </Grid>

    <Grid Grid.Column = '2' Grid.Row = '2' ShowGridLines = 'false' MinHeight="20" MinWidth="20">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width ='*'></ColumnDefinition>
        <ColumnDefinition Width ='Auto'></ColumnDefinition>
      </Grid.ColumnDefinitions>
      <TextBox Padding="2" Margin="2" x:Name = 'Input_txt' AcceptsReturn = 'True' VerticalScrollBarVisibility='Visible' TextWrapping = 'Wrap'
                  Grid.Column = '0' HorizontalAlignment = 'Stretch' />
      <Button Padding="2" Margin="2" x:Name = 'Send_btn'   Content = 'Send' Grid.Column = '1'/>
    </Grid>
    <!--</StackPanel>-->

  </Grid>
</DockPanel>

</Window>
"@
      # Load XAML
      $reader = (New-Object System.Xml.XmlNodeReader $xaml)
      $Window = [Windows.Markup.XamlReader]::Load($reader)

      # Controls
      [xml]$Script:AllMessagesXML = '<messages xmlns=""></messages>'

      $Script:WindowMessagesXML = $Window.FindName('xmlMessages')
      $Script:WindowSubjectListXML = $Window.FindName('xmlSubjectList')
      
      #$Script:OnlineUsers = $Window.FindName('OnlineUsers')

      $SendButton = $Window.FindName('Send_btn')
      $Script:ConnectButton = $Window.FindName('Connect_btn')
      $DisconnectButton = $Window.FindName('Disconnect_btn')
      $Username_txt = $Window.FindName('username_txt')
      #$Server_txt = $Window.FindName('servername_txt')
      $Inputbox_txt = $Window.FindName('Input_txt')
      #$Script:MainMessage = $Window.FindName('MainMessage_txt')
      #$ExitMenu = $Window.FindName('ExitMenu')
      #$SaveTranscript = $Window.FindName('SaveTranscript')

      # Events
      # ExitMenu
      #$ExitMenu.Add_Click({
      #  $Window.Close()
      #})

      #SaveTranscriptMenu
      #$SaveTranscript.Add_Click({
      #  Save-Transcript
      #})

      #Connect
      $ConnectButton.Add_Click({
        # Get Server IP
        $Server = 'localhost'

        # Get Username
        # TODO Is global even needed?
        $Global:Username = $Username_txt.text
        If ($username -match "^[A-Za-z0-9_!]*$") {
          $ConnectButton.IsEnabled = $False
          $DisconnectButton.IsEnabled = $True
          If ($Server -AND $Username) {
            Write-Verbose "Connecting to {0} as {1} ..." -f $Server,$username

            #Connect to server
            $Endpoint = new-object System.Net.IPEndpoint ([ipaddress]::any,$SourcePort)
            $TcpClient = [Net.Sockets.TCPClient]$endpoint
            Try {
              $TcpClient.Connect($Server,15600)
              # TODO Is global even needed?
              $Global:ServerStream = $TcpClient.GetStream()
              $data = [text.Encoding]::Ascii.GetBytes($Username)
              $ServerStream.Write($data,0,$data.length)
              $ServerStream.Flush()
              If ($TcpClient.Connected) {
                $Window.Title = ("{0}: Connected as {1}" -f $Window.Title,$Username)
                #Kick off a job to watch for messages from clients
                $newRunspace = [RunSpaceFactory]::CreateRunspace()
                $newRunspace.Open()
                $newRunspace.SessionStateProxy.setVariable("TcpClient", $TcpClient)
                $newRunspace.SessionStateProxy.setVariable("MessageQueue", $MessageQueue)
                $newRunspace.SessionStateProxy.setVariable("ConnectButton", $ConnectButton)
                $newPowerShell = [PowerShell]::Create()
                $newPowerShell.Runspace = $newRunspace
                $sb = {
                  #Code to kick off client connection monitor and look for incoming messages.
                  $client = $TCPClient
                  $serverstream = $Client.GetStream()
                  #While client is connected to server, check for incoming traffic
                  While ($client.Connected) {
                    Try {
                      [byte[]]$inStream = New-Object byte[] 200KB
                      $buffSize = $client.ReceiveBufferSize
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
                  $client.Client.Disconnect($True)
                  $client.Client.Close()
                  $client.Close()
                  $ConnectButton.IsEnabled = $True
                  $DisconnectButton.IsEnabled = $False
                }
                $job = "" | Select Job, PowerShell
                $job.PowerShell = $newPowerShell
                $Job.job = $newPowerShell.AddScript($sb).BeginInvoke()
                $ClientConnection.$Username = $job
              }
            } Catch {
              #Errors Connecting to server
              Write-Warning "Unable to connect to {0}! Please try again later!" -f $RemoteServer
              $ConnectButton.IsEnabled = $True
              $TcpClient.Close()
              $ClientConnection.user.PowerShell.EndInvoke($ClientConnections.user.Job)
              $ClientConnection.user.PowerShell.Runspace.Close()
              $ClientConnection.user.PowerShell.Dispose()
            }
          }
        } Else {
          #Username is not in correct format
          Write-Warning "`'{0}`' is not a valid username! Acceptable characters are 'A-Za-z0-9!_'. Spaces are not allowed!" -f $username
        }
      })

      #Send message
      $SendButton.Add_Click({
        #Send message to server
        If (($Inputbox_txt.Text).StartsWith("@")) {
          $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
        }
        $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
        $data = [text.Encoding]::Ascii.GetBytes($Message)
        $ServerStream.Write($data,0,$data.length)
        $ServerStream.Flush()
        $Inputbox_txt.Clear()
      })

      #Load Window
      $Window.Add_Loaded({
        #Dictionary of colors for Fonts
        $script:colors = @{}
        $Color = [windows.media.colors] | Get-Member -static -Type Property | Select -Expand Name | ForEach {
            $colors["$([windows.media.colors]::$_)"] = $_
            $colors[$_] = "$([windows.media.colors]::$_)"
        }
        #Date placeholder for later use
        $Global:Date = Get-Date -Format ddMMyyyy
        #Used for managing the queue of messages in an orderly fashion
        $Global:MessageQueue =  [System.Collections.Queue]::Synchronized((New-Object System.collections.queue))
        #Used for managing client connection
        $Global:ClientConnection = [hashtable]::Synchronized(@{})
        #Create Timer object
        $Global:timer = New-Object System.Windows.Threading.DispatcherTimer
        #Fire off every 1 seconds
        $timer.Interval = [TimeSpan]"0:0:1.00"
        #Add event per tick
        $timer.Add_Tick({
          [Windows.Input.InputEventHandler]{ $Global:Window.UpdateLayout() }
          If ($Messagequeue.Count -gt 0) {
            $Message = $Messagequeue.Dequeue()
            [Console]::WriteLine("Raw Message $Message")
            $MessageID = $null
            if ($Message.StartsWith("!")) {
              # The message has an ID. Extract it and send the message on for parsing.
              $Message = $Message.Substring(1)
              $MessageID = $Message.Substring(0,32)
              $Message = $Message.SubString(32 + 1)
            }
            Switch ($Message) {
              {$_.Startswith("~B")} {
                # Message
                $data = ($_).SubString(2)
                $split = $data -split ("{0}" -f "~~")
                [Console]::WriteLine("Not Implmented $_")
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Orange))
              }
              {$_.Startswith("~I")} {
                # Message
                $data = ($_).SubString(2)
                $split = $data -split ("{0}" -f "~~")
                [Console]::WriteLine("Not Implmented $_")
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                #$Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Blue))
              }
              {$_.Startswith("~M")} {
                # Message
                $data = ($_).SubString(2)
                $split = $data -split ("{0}" -f "~~")

                $tmpDoc = [xml]($Script:WindowMessagesXML.Document.OuterXml)
                $xmlItem = $tmpDoc.CreateElement('message')
                $xmlItem.SetAttribute('timestamp', (Get-Date -UFormat '%a, %d %b %Y %H:%M:%S'))
                $xmlItem.SetAttribute('from',$split[0])
                $xmlItem.SetAttribute('id',$MessageID)
                $xmlItem.InnerText = $split[1]
                $tmpDoc.messages.AppendChild($xmlItem) | Out-Null
                $Script:WindowMessagesXML.Document = $tmpDoc
              }
              {$_.Startswith("~D")} {
                # Disconnect
                $username = $_.SubString(2)
                $tmpDoc = [xml]($Script:WindowSubjectListXML.Document.OuterXml)
                $result = $tmpDoc.SelectSingleNode("/subjects/subject[@subjecttype='user' and @id='$($username)']")
                if ($result -ne $null) {
                  $result.ParentNode.RemoveChild($result) | Out-Null
                  $Script:WindowSubjectListXML.Document = $tmpDoc
                }
              }
              {$_.StartsWith("~C")} {
                #Connect
                $username = $_.SubString(2)
                $tmpDoc = [xml]($Script:WindowSubjectListXML.Document.OuterXml)
                $result = $tmpDoc.SelectSingleNode("/subjects/subject[@subjecttype='user' and @id='$($username)']")
                if ($result -eq $null) {
                  $xmlItem = $tmpDoc.CreateElement('subject')
                  $xmlItem.SetAttribute('name',$username)
                  $xmlItem.SetAttribute('id',$username)
                  $xmlItem.SetAttribute('subjecttype','user')
                  $tmpDoc.subjects.AppendChild($xmlItem) | Out-Null
                  $Script:WindowSubjectListXML.Document = $tmpDoc
                }
              }
              {$_.StartsWith("~S")} {
                #Server Shutdown
                $TcpClient.Close()
                $ClientConnection.user.PowerShell.EndInvoke($ClientConnections.user.Job)
                $ClientConnection.user.PowerShell.Runspace.Close()
                $ClientConnection.user.PowerShell.Dispose()
                $ConnectButton.IsEnabled = $True
                $DisconnectButton.IsEnabled = $False
                $Script:WindowMessagesXML.Document = '<messages xmlns=""></messages>'
                $Script:WindowSubjectListXML.Document = '<subjects xmlns=""></subjects>'
              }
              {$_.StartsWith("~Z")} {
                [xml]$SubjectListXML = '<subjects xmlns=""><subject name="Lobby" subjecttype="room" id="-1" /></subjects>'
                #List of connected users
                $online = (($_).SubString(2) -split "~~")
                #Add online users to window
                $Online | ForEach {
                  $xmlItem = $SubjectListXML.CreateElement('subject')
                  $xmlItem.SetAttribute('name',$_)
                  $xmlItem.SetAttribute('id',$_)
                  $xmlItem.SetAttribute('subjecttype','user')
                  $SubjectListXML.subjects.AppendChild($xmlItem) | Out-Null
                }
                $Script:WindowSubjectListXML.Document = $SubjectListXML
              }
              Default {
                $MainMessage.text += ("[{0}] {1}" -f (Get-Date).ToLongTimeString(),$_)
              }
            }
          }
        })
        #Start timer
        $timer.Start()
        If (-NOT $timer.IsEnabled) {
          $Window.Close()
        }
      })
      #Close Window
      $Window.Add_Closed({
        If ($TcpClient) {
          $TcpClient.Close()
        }
        If ($ClientConnection.user) {
          $ClientConnection.user.PowerShell.EndInvoke($ClientConnection.user.Job)
          $ClientConnection.user.PowerShell.Runspace.Close()
          $ClientConnection.user.PowerShell.Dispose()
        }
      })

      #Disconnect from server
      $DisconnectButton.Add_Click({
        #Shutdown client runspace and socket
        $TcpClient.Close()
        $ClientConnection.user.PowerShell.EndInvoke($ClientConnection.user.Job)
        $ClientConnection.user.PowerShell.Runspace.Close()
        $ClientConnection.user.PowerShell.Dispose()
        $ConnectButton.IsEnabled = $True
        $DisconnectButton.IsEnabled = $False
        $Script:WindowMessagesXML.Document = '<messages xmlns=""></messages>'
        $Script:WindowSubjectListXML.Document = '<subjects xmlns=""></subjects>'
      })

      $Window.Add_KeyDown({
        $key = $_.Key
        If ([System.Windows.Input.Keyboard]::IsKeyDown("RightCtrl") -OR [System.Windows.Input.Keyboard]::IsKeyDown("LeftCtrl")) {
          Switch ($Key) {
          "RETURN" {
            Write-Verbose ("Sending message")
            If (($Inputbox_txt.Text).StartsWith("@")) {
                $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
            }
            $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
            $data = [text.Encoding]::Ascii.GetBytes($Message)
            $ServerStream.Write($data,0,$data.length)
            $ServerStream.Flush()
            $Inputbox_txt.Clear()
          }
          Default {$Null}
          }
        }
      })

      Write-Verose "Showing client..."
      $Script:WindowMessagesXML.Document = '<messages xmlns=""></messages>'
      $Script:WindowSubjectListXML.Document = '<subjects xmlns=""></subjects>'

      [void]$Window.showDialog()

    }).Invoke()
  }
}

#Export-ModuleMember -Function Invoke-PostBotTestServerClient