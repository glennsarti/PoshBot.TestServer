using System;
using Microsoft.AspNet.SignalR.Client;

// Install-Package Microsoft.AspNet.SignalR.Client

namespace PoshBotTestServer
{
  class ConsoleClient
  {
    private static readonly object syncLock = new object();
    private static string CurrentRoom = null;
    private static string CurrentRoomID = null;

    static private void DisplayRoomList(PoshBotTestServer.Common.RoomList roomList)
    {
      lock(syncLock)
      {
        Console.WriteLine();
        Console.WriteLine("Room List");
        foreach (PoshBotTestServer.Common.Room room in roomList)
        {
          Console.WriteLine(" - {0}", room.Name);
        }
        WritePrompt();
      }
    }

    static private void JoinedRoom(PoshBotTestServer.Common.Room room)
    {
      CurrentRoom = room.Name;
      CurrentRoomID = room.RoomID.ToString();

      lock (syncLock)
      {
        Console.WriteLine();
        WritePrompt();
      }
    }

    static private void LeftRoom(PoshBotTestServer.Common.Room room)
    {
      CurrentRoom = null;
      CurrentRoomID = null;

      lock (syncLock)
      {
        Console.WriteLine();
        WritePrompt();
      }
    }


    static private void DisplayMessage(PoshBotTestServer.Common.Message Message)
    {
      lock(syncLock)
      {
        ConsoleColor originalColor = Console.ForegroundColor;
        ConsoleColor originalBackColor = Console.BackgroundColor;
        if (Message.ChannelId == null)
        {
          Console.WriteLine();
          Console.ForegroundColor = ConsoleColor.White;
          Console.BackgroundColor = ConsoleColor.DarkRed;
          Console.Write("[{0}]", Message.FromUsername);
          Console.ForegroundColor = ConsoleColor.White;
          Console.BackgroundColor = ConsoleColor.Black;
          Console.WriteLine(" {0}", Message.Text);

          Console.ForegroundColor = originalColor;
          Console.BackgroundColor = originalBackColor;
          WritePrompt();
        }
        else
        {
          Console.WriteLine();
          Console.ForegroundColor = ConsoleColor.White;
          Console.BackgroundColor = ConsoleColor.DarkBlue;
          Console.Write("[{0}]", Message.ChannelName);
          Console.ForegroundColor = ConsoleColor.White;
          Console.BackgroundColor = ConsoleColor.DarkRed;
          Console.Write("[{0}]", Message.FromUsername);
          Console.ForegroundColor = ConsoleColor.White;
          Console.BackgroundColor = ConsoleColor.Black;
          Console.WriteLine(" {0}", Message.Text);

          Console.ForegroundColor = originalColor;
          Console.BackgroundColor = originalBackColor;
          WritePrompt();
        }
      }
    }

    static private void WritePrompt()
    {
      // DO NOT synclock
      if (CurrentRoom == null)
      {
        Console.Write("> ");
      }
      else
      {
        Console.Write("[{0}]> ", CurrentRoom);
      }
    }

    static void Main(string[] args)
    {
      String serverURL = null;
      String MyUsername = null;
      String MyPassword = null;

      if (args.Length > 0) { serverURL = args[0]; }
      if (args.Length > 1) { MyUsername = args[1]; }
      if (args.Length > 2) { MyPassword = args[2]; }

      if (args.Length == 0)
      {
        Console.WriteLine("Usage: client.exe <URL to ChatServer> <Username> <Password>");
      }

      while (serverURL == null || serverURL == "")
      {
        Console.WriteLine();
        Console.Write("Please enter the URL for ChatServer (default: http://localhost:8080): ");
        serverURL = Console.ReadLine().Trim();
        if (serverURL == "") { serverURL = "http://localhost:8080"; }
      }
      while (MyUsername == null || MyUsername == "")
      {
        Console.WriteLine();
        Console.Write("Please your username: ");
        MyUsername = Console.ReadLine().Trim();
      }
      while (MyPassword == null || MyPassword == "")
      {
        Console.WriteLine();
        Console.Write("Please your password: ");
        MyPassword = Console.ReadLine().Trim();
      }
      Console.WriteLine("Starting client to server {0}",serverURL);

      var hubConnection = new HubConnection(serverURL);
      //hubConnection.TraceLevel = TraceLevels.All;
      //hubConnection.TraceWriter = Console.Out;
      IHubProxy myHubProxy = hubConnection.CreateHubProxy("PoshBotChatHub");

      // Send my username when the server requests it.
      myHubProxy.On("RequestAuthentication", () => myHubProxy.Invoke("Authenticate", MyUsername, MyPassword));
      myHubProxy.On<PoshBotTestServer.Common.RoomList>("RoomList", roomList => DisplayRoomList(roomList));
      myHubProxy.On<PoshBotTestServer.Common.Message>("ServerMessage", msg => DisplayMessage(msg));
      myHubProxy.On<PoshBotTestServer.Common.Room>("JoinedRoom", room => JoinedRoom(room));
      myHubProxy.On<PoshBotTestServer.Common.Room>("LeftRoom", room => LeftRoom(room));

      hubConnection.Start().Wait();
      Console.WriteLine("Type /HELP to get help");
      while (true)
      {
        WritePrompt();
        string textInput = Console.ReadLine();
        if (textInput == null)
        {
          // Happens when Ctrl-C is keyed.  Same as /EXIT
          break;
        }
        if (textInput.ToUpper() == "/HELP")
        {
          lock (syncLock)
          {
            Console.WriteLine("/Rooms            - List Available Rooms");
            Console.WriteLine("/Join <roomname>  - Join a room");
            Console.WriteLine("/Leave <roomname> - Leave a room");
            Console.WriteLine("/Exit             - Quit");
            Console.WriteLine();
          }
        }
        if (textInput.ToUpper().StartsWith("/JOIN "))
        {
          String roomName = textInput.Substring(6).Trim();
          myHubProxy.Invoke("JoinRoom",roomName);
        }
        if (textInput.ToUpper().StartsWith("/LEAVE "))
        {
          String roomName = textInput.Substring(7).Trim();
          myHubProxy.Invoke("LeaveRoom", roomName);
        }
        if (textInput.ToUpper() == "/ROOMS")
        {
          myHubProxy.Invoke("GetRooms");
        }
        if (textInput.ToUpper() == "/EXIT")
        {
          break;
        }
        if (!textInput.StartsWith("/") && CurrentRoomID != null && textInput.Trim() != "")
        {
          myHubProxy.Invoke("ClientRoomMessage", CurrentRoomID, textInput);
        }
      }

      Console.WriteLine("Closing down connection...");
      hubConnection.Stop();
      hubConnection.Dispose();
    }
  }
}