using System;
using Microsoft.AspNet.SignalR;
using Microsoft.Owin.Hosting;
using Owin;
using Microsoft.Owin.Cors;
using Microsoft.Owin;
using System.Threading.Tasks;

// Install-Package Microsoft.AspNet.SignalR.SelfHost
// Install-Package Microsoft.Owin.Cors

[assembly: OwinStartup(typeof(PoshBotTestServer.Startup))]

namespace PoshBotTestServer
{
  class Server
  {
    static void Main(string[] args)
    {

      // This will *ONLY* bind to localhost, if you want to bind to all addresses
      // use http://*:8080 to bind to all addresses. 
      // See http://msdn.microsoft.com/en-us/library/system.net.httplistener.aspx 
      // for more information.
      string url = "http://localhost:8080";
      using (WebApp.Start(url))
      {
        Console.WriteLine("Server running on {0}", url);
        Console.ReadLine();
      }
    }
  }

  class Startup
  {
    public void Configuration(IAppBuilder app)
    {
      // Branch the pipeline here for requests that start with "/signalr"
      app.Map("/signalr", map =>
      {
        // Setup the CORS middleware to run before SignalR.
        // By default this will allow all origins. You can 
        // configure the set of origins and/or http verbs by
        // providing a cors options with a different policy.
        map.UseCors(CorsOptions.AllowAll);
        var hubConfiguration = new HubConfiguration
        {
          // You can enable JSONP by uncommenting line below.
          // JSONP requests are insecure but some older browsers (and some
          // versions of IE) require JSONP to work cross domain
          // EnableJSONP = true
        };
        // Run the SignalR pipeline. We're not using MapSignalR
        // since this branch already runs under the "/signalr"
        // path.

        hubConfiguration.EnableDetailedErrors = true;
        map.RunSignalR(hubConfiguration);
      });
    }
  }

  public static class Helper
  {
    public static Common.Message FromServerMessage(PoshBotTestServer.Common.User User, String Message)
    {
      Common.Message msg = new Common.Message();
      msg.ChannelId = null;
      msg.FromUserId = 0;
      msg.FromUsername = "SERVER";
      msg.ToUserId = User.UserId;
      msg.ToUsername = User.Username;
      msg.Subtype = Common.MessageSubtype.None;
      msg.Type = Common.MessageType.Message;
      msg.Text = Message;
      return msg;
    }

    public static Common.Message UserJoinedMessage(PoshBotTestServer.Common.User User, ChatRoom room)
    {
      Common.Message msg = new Common.Message();
      msg.ChannelId = room.RoomID.ToString();
      msg.ChannelName = room.Name;
      msg.FromUserId = 0;
      msg.FromUsername = "SERVER";
      msg.Subtype = Common.MessageSubtype.ChannelJoined;
      msg.Type = Common.MessageType.Message;
      msg.Text = User.Username + " has joined " + room.Name;
      return msg;
    }

    public static Common.Message UserLeftMessage(PoshBotTestServer.Common.User User, ChatRoom room)
    {
      Common.Message msg = new Common.Message();
      msg.ChannelId = room.RoomID.ToString();
      msg.ChannelName = room.Name;
      msg.FromUserId = 0;
      msg.FromUsername = "SERVER";
      msg.Subtype = Common.MessageSubtype.ChannelLeft;
      msg.Type = Common.MessageType.Message;
      msg.Text = User.Username + " has left " + room.Name;
      return msg;
    }

    public static Common.Message RoomMessage(PoshBotTestServer.Common.User User, ChatRoom room, String Text)
    {
      Common.Message msg = new Common.Message();
      msg.ChannelId = room.RoomID.ToString();
      msg.ChannelName = room.Name;
      msg.FromUserId = User.UserId;
      msg.FromUsername = User.Username;
      msg.Subtype = Common.MessageSubtype.None;
      msg.Type = Common.MessageType.Message;
      msg.Text = Text;
      return msg;
    }
  }

  public class PoshBotChatHub : Hub
  {
    private static ChatStore _ChatStore = new ChatStore();

    private void SendPrivateMessage(string ConnectionID, Common.Message Message)
    {
      Clients.Client(ConnectionID).ServerMessage(Message);
      Console.WriteLine("Sending Private Message from {0} to {1}", Message.FromUsername, Message.ToUsername);
    }
    private void SendGroupMessage(string SignalRGroup, Common.Message Message)
    {
      Clients.Group(SignalRGroup).ServerMessage(Message);
      Console.WriteLine("Sending Group Message from {0} to {1}", Message.FromUsername, SignalRGroup);

      Console.WriteLine("{0}", Message.Text);

    }

    #region "SignalR Inbound RPC Handlers"

    public void Authenticate(String Username, String Password)
    {
      if (_ChatStore.GetUserByConnectionID(Context.ConnectionId) != null) { return; }
      ChatUser thisUser = _ChatStore.AuthenticateUser(Context.ConnectionId, Username, Password);
      if (thisUser == null) { return; }

      Console.WriteLine("User {0} has authenticated on connection {1}", thisUser.Username, Context.ConnectionId);

      SendPrivateMessage(Context.ConnectionId, Helper.FromServerMessage(thisUser,"Welcome to the PoshBot Test Server"));
    }

    public void SetUsername(String Username)
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser == null) { return; }

      // TODO Check if this username is already Taken
      if (_ChatStore.SetUsername(thisUser, Username))
      {
        Console.WriteLine("User {0} Changed username from {1} to {2}", thisUser.UserId, thisUser.Username, Username);
      }
      // TODO Broadcast name change to all other clients?
    }

    public void ClientRoomMessage(String ChannelID, String Text)
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser == null) { return; }
      ChatRoom thisRoom = _ChatStore.GetRoomByRoomID(ChannelID);
      if (thisRoom == null) { return; }

      if (!_ChatStore.UserInRoom(thisUser,thisRoom)) { return; }

      SendGroupMessage(thisRoom.SignalRRoomID, Helper.RoomMessage(thisUser, thisRoom, Text));
    }

    public async Task JoinRoom(String roomName)
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser == null) { return; }
      ChatRoom thisRoom = _ChatStore.GetRoomByName(roomName);

      if (thisRoom == null) { thisRoom = _ChatStore.AddRoom(roomName, roomName); }
      if (_ChatStore.UserInRoom(thisUser, thisRoom))
      {
        Console.WriteLine("User {0} tried to rejoin room {1}", thisUser.UserId, thisRoom.RoomID);
        return;
      }
      await Groups.Add(Context.ConnectionId, thisRoom.SignalRRoomID);
      _ChatStore.AddUserToRoom(thisUser, thisRoom);
      Clients.Client(Context.ConnectionId).JoinedRoom(thisRoom);
      SendGroupMessage(thisRoom.SignalRRoomID, Helper.UserJoinedMessage(thisUser, thisRoom));
    }

    public async Task LeaveRoom(String roomName)
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser == null) { return; }
      ChatRoom thisRoom = _ChatStore.GetRoomByName(roomName);
      if (thisRoom == null) { return; }

      if (thisRoom == null) { thisRoom = _ChatStore.AddRoom(roomName, roomName); }
      if (!_ChatStore.UserInRoom(thisUser, thisRoom))
      {
        Console.WriteLine("User {0} tried to leave room {1} which they are not in", thisUser.UserId, thisRoom.RoomID);
        return;
      }
      await Groups.Remove(Context.ConnectionId, thisRoom.SignalRRoomID);
      _ChatStore.RemoveUserFromRoom(thisUser, thisRoom);
      Clients.Client(Context.ConnectionId).LeftRoom(thisRoom);
      SendGroupMessage(thisRoom.SignalRRoomID, Helper.UserLeftMessage(thisUser, thisRoom));
    }

    public void GetRooms()
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser == null) { return; }

      Console.WriteLine("User {0} requested room list", thisUser.UserId);

      Clients.Client(Context.ConnectionId).RoomList(_ChatStore.RoomList());
    }
    #endregion

    #region "SignalR Hub Overrides"
    public override Task OnConnected()
    {
      Console.WriteLine("Hub OnConnected Client Id {0}", Context.ConnectionId);
      Clients.Client(Context.ConnectionId).RequestAuthentication();
      return base.OnConnected();
    }

    public override Task OnDisconnected(bool stopCalled)
    {
      ChatUser thisUser = _ChatStore.GetUserByConnectionID(Context.ConnectionId);
      if (thisUser != null)
      {
        ChatRoomList roomList = _ChatStore.RemoveUserByConnectionId(Context.ConnectionId);
        foreach (ChatRoom room in roomList)
        {
          SendGroupMessage(room.SignalRRoomID, Helper.UserLeftMessage(thisUser, room));
        }
      }
      else
      {
        Console.WriteLine("Hub OnDisconnected {0}", Context.ConnectionId);
      }
      return base.OnDisconnected(stopCalled);
    }

    public override Task OnReconnected()
    {
      Console.WriteLine("Hub OnReconnected {0}", Context.ConnectionId);
      return base.OnReconnected();
    }
    #endregion

  }
}
