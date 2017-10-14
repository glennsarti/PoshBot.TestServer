Function Invoke-PoshBotTestServerAutoClient {
  [cmdletbinding()]
  Param (
  )

  Begin {
    $loremText = @"
ACT I
SCENE I. A desert place.

Thunder and lightning. Enter three Witches 
First Witch 
When shall we three meet again
In thunder, lightning, or in rain?

Second Witch 
When the hurlyburly's done,
When the battle's lost and won.

Third Witch 
That will be ere the set of sun.

First Witch 
Where the place?

Second Witch 
Upon the heath.

Third Witch 
There to meet with Macbeth.

First Witch 
I come, Graymalkin!

Second Witch 
Paddock calls.

Third Witch 
Anon.

ALL 
Fair is foul, and foul is fair:
Hover through the fog and filthy air.

Exeunt

SCENE II. A camp near Forres.

Alarum within. Enter DUNCAN, MALCOLM, DONALBAIN, LENNOX, with Attendants, meeting a bleeding Sergeant 
DUNCAN 
What bloody man is that? He can report,
As seemeth by his plight, of the revolt
The newest state.

MALCOLM 
This is the sergeant
Who like a good and hardy soldier fought
'Gainst my captivity. Hail, brave friend!
Say to the king the knowledge of the broil
As thou didst leave it.

Sergeant 
Doubtful it stood;
As two spent swimmers, that do cling together
And choke their art. The merciless Macdonwald--
Worthy to be a rebel, for to that
The multiplying villanies of nature
Do swarm upon him--from the western isles
Of kerns and gallowglasses is supplied;
And fortune, on his damned quarrel smiling,
Show'd like a rebel's whore: but all's too weak:
For brave Macbeth--well he deserves that name--
Disdaining fortune, with his brandish'd steel,
Which smoked with bloody execution,
Like valour's minion carved out his passage
Till he faced the slave;
Which ne'er shook hands, nor bade farewell to him,
Till he unseam'd him from the nave to the chaps,
And fix'd his head upon our battlements.

DUNCAN 
O valiant cousin! worthy gentleman!

Sergeant 
As whence the sun 'gins his reflection
Shipwrecking storms and direful thunders break,
So from that spring whence comfort seem'd to come
Discomfort swells. Mark, king of Scotland, mark:
No sooner justice had with valour arm'd
Compell'd these skipping kerns to trust their heels,
But the Norweyan lord surveying vantage,
With furbish'd arms and new supplies of men
Began a fresh assault.

DUNCAN 
Dismay'd not this
Our captains, Macbeth and Banquo?

Sergeant 
Yes;
As sparrows eagles, or the hare the lion.
If I say sooth, I must report they were
As cannons overcharged with double cracks, so they
Doubly redoubled strokes upon the foe:
Except they meant to bathe in reeking wounds,
Or memorise another Golgotha,
I cannot tell.
But I am faint, my gashes cry for help.

DUNCAN 
So well thy words become thee as thy wounds;
They smack of honour both. Go get him surgeons.

Exit Sergeant, attended

Who comes here?

Enter ROSS

MALCOLM 
The worthy thane of Ross.

LENNOX 
What a haste looks through his eyes! So should he look
That seems to speak things strange.

ROSS 
God save the king!

DUNCAN 
Whence camest thou, worthy thane?

ROSS 
From Fife, great king;
Where the Norweyan banners flout the sky
And fan our people cold. Norway himself,
With terrible numbers,
Assisted by that most disloyal traitor
The thane of Cawdor, began a dismal conflict;
Till that Bellona's bridegroom, lapp'd in proof,
Confronted him with self-comparisons,
Point against point rebellious, arm 'gainst arm.
Curbing his lavish spirit: and, to conclude,
The victory fell on us.

DUNCAN 
Great happiness!

ROSS 
That now
Sweno, the Norways' king, craves composition:
Nor would we deign him burial of his men
Till he disbursed at Saint Colme's inch
Ten thousand dollars to our general use.

DUNCAN 
No more that thane of Cawdor shall deceive
Our bosom interest: go pronounce his present death,
And with his former title greet Macbeth.

ROSS 
I'll see it done.

DUNCAN 
What he hath lost noble Macbeth hath won.

Exeunt

SCENE III. A heath near Forres.

Thunder. Enter the three Witches 
First Witch 
Where hast thou been, sister?

Second Witch 
Killing swine.

Third Witch 
Sister, where thou?

First Witch 
A sailor's wife had chestnuts in her lap,
And munch'd, and munch'd, and munch'd:--
'Give me,' quoth I:
'Aroint thee, witch!' the rump-fed ronyon cries.
Her husband's to Aleppo gone, master o' the Tiger:
But in a sieve I'll thither sail,
And, like a rat without a tail,
I'll do, I'll do, and I'll do.

Second Witch 
I'll give thee a wind.

First Witch 
Thou'rt kind.

Third Witch 
And I another.

First Witch 
I myself have all the other,
And the very ports they blow,
All the quarters that they know
I' the shipman's card.
I will drain him dry as hay:
Sleep shall neither night nor day
Hang upon his pent-house lid;
He shall live a man forbid:
Weary se'nnights nine times nine
Shall he dwindle, peak and pine:
Though his bark cannot be lost,
Yet it shall be tempest-tost.
Look what I have.

Second Witch 
Show me, show me.

First Witch 
Here I have a pilot's thumb,
Wreck'd as homeward he did come.

Drum within

Third Witch 
A drum, a drum!
Macbeth doth come.
"@
  }

  Process {
    $localPort = 15600
    $botName = 'Shakespeare'

    #Connect to server
    $Endpoint = new-object System.Net.IPEndpoint ([ipaddress]::any,0)
    $TcpClient = [Net.Sockets.TCPClient]$endpoint
    Try {
      Write-Verbose "Connecting to PoshBot Test server 127.0.0.1:${localPort}"
      $TcpClient.Connect('127.0.0.1',$localPort)
      $ServerStream = $TcpClient.GetStream()
      $data = [text.Encoding]::Ascii.GetBytes($botName)
      $ServerStream.Write($data,0,$data.length)
      $ServerStream.Flush()
      If ($TcpClient.Connected) {
        $Connected = $true
        #Kick off a job to watch for messages from clients
        $newRunspace = [RunSpaceFactory]::CreateRunspace()
        $newRunspace.Open()
        $newRunspace.SessionStateProxy.setVariable("TcpClient", $TcpClient)
        #$newRunspace.SessionStateProxy.setVariable("MessageQueue", $MessageQueue)
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
            } Catch {
              #Connection to server has been closed
              # TODO If the connection is broken why send a message?
              # $Messagequeue.Enqueue("~S")
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
        $ConnectionJob = $job
      }
    } Catch {
      #Errors Connecting to server
      Write-Warning "Error $_"
      $TcpClient.Close()
      $ConnectionJob.PowerShell.EndInvoke($ConnectionJob)
    }

    Write-Verbose "Starting AutoClient..."
    $loremText.split("`n") | % {
      $text = $_.Trim()
      if ($text -ne '') {
        $Message = "~M{0}{1}{2}" -f ($botName), "~~", ($text)
        $data = [text.Encoding]::Ascii.GetBytes($Message)
        $ServerStream.Write($data,0,$data.length)
        $ServerStream.Flush()
        Start-Sleep -Seconds 2
      }
    }
  }
}

#Invoke-PoshBotTestServerAutoClient -Verbose
