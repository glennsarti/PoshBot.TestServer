using System;
using System.Collections.Generic;

namespace PoshBotTestServer
{
  // Extend the Room class
  public class ChatRoom : PoshBotTestServer.Common.Room
  {
    public System.Collections.Generic.Queue<PoshBotTestServer.Common.Message> MessageHistory = new System.Collections.Generic.Queue<PoshBotTestServer.Common.Message>();
    public System.Collections.Generic.List<Int32> UserList = new List<Int32>();
    private readonly object syncLock = new object();

    public string SignalRRoomID
    {
      get
      {
        return "ROOM" + this.RoomID.ToString();
      }
    }

    public ChatRoom Clone()
    {
      ChatRoom result = new ChatRoom();
      result.Name = this.Name;
      result.Title = this.Title;
      result.RoomID = this.RoomID;
      return result;
    }
  }

  public class ChatRoomList : System.Collections.Generic.List<ChatRoom> { }

  // Extend the User class
  public class ChatUser : PoshBotTestServer.Common.User
  {
    public System.Collections.Generic.List<String> Connections = new List<String>();

    public ChatUser Clone()
    {
      ChatUser result = new ChatUser();
      result.UserId = this.UserId;
      result.Username = this.Username;
      return result;
    }
  }


  public class ChatStore
  {
    private System.Collections.Generic.List<ChatRoom> ChatRooms = new System.Collections.Generic.List<ChatRoom>();
    private System.Collections.Generic.List<ChatUser> ChatUsers = new System.Collections.Generic.List<ChatUser>();
    private readonly object syncLock = new object();
    private readonly Random rnd = new Random();

    public ChatUser AuthenticateUser(String Connectionid, String Username, String Password)
    {
      if (Username != Password) { return null; }

      // TODO search for pre-existing connections and just append? Need to check by username
      ChatUser thisUser = new ChatUser();
      thisUser.Username = Username;
      thisUser.Connections.Add(Connectionid);
      lock (syncLock)
      {
        thisUser.UserId = rnd.Next();
        ChatUsers.Add(thisUser);
      }

      return thisUser.Clone() as ChatUser;
    }

    public ChatRoomList RemoveUserByConnectionId(String ConnectionId)
    {
      ChatRoomList roomList = new ChatRoomList();
      lock (syncLock)
      {
        ChatUser thisUser = null;
        foreach (ChatUser user in ChatUsers)
        {
          if (user.Connections.IndexOf(ConnectionId) != -1) { thisUser = user; }
        }
        if (thisUser == null) return roomList;
        // Remove the connectionid from the user
        thisUser.Connections.Remove(ConnectionId);

        foreach (ChatRoom room in ChatRooms)
        {
          if (room.UserList.IndexOf(thisUser.UserId) != -1)
          {
            // Remove the user from the room
            roomList.Add(room.Clone());
            room.UserList.Remove(thisUser.UserId);
          }
        }

        // TODO
        // Remove users with no connectionIds
        // Remove rooms with no users (except for Id 0)
      }
      return roomList;
    }

    public bool SetUsername(ChatUser User, String NewUsername)
    {
      lock (syncLock)
      {
        foreach(ChatUser item in ChatUsers)
        {
          if (item.UserId == User.UserId)
          {
            item.Username = NewUsername;
            return true;
          }
        }
      }
      return false;
    }

    public ChatUser GetUserByConnectionID(String ConnectionId)
    {
      lock (syncLock)
      {
        foreach (ChatUser user in ChatUsers)
        {
          if (user.Connections.IndexOf(ConnectionId) != -1) { return user.Clone(); }
        }
      }
      return null;
    }

    public ChatRoom GetRoomByRoomID(String ChannelID)
    {
      lock (syncLock)
      {
        // Does the room exist
        foreach (ChatRoom room in ChatRooms)
        {
          if (room.RoomID.ToString() == ChannelID)
          {
            return room.Clone();
          }
        }
      }
      return null;
    }

    public ChatRoom AddRoom(String Name, String Description)
    {
      if (Description == null) { Description = Name; }
      ChatRoom thisRoom = new ChatRoom();
      thisRoom.Name = Name;
      thisRoom.Title = Description;

      lock (syncLock)
      {
        thisRoom.RoomID = rnd.Next();
        ChatRooms.Add(thisRoom);
      }
      return thisRoom.Clone() as ChatRoom;
    }

    public ChatRoom GetRoomByName(String RoomName)
    {
      lock (syncLock)
      {
        // Does the room exist
        foreach (ChatRoom room in ChatRooms)
        {
          if (room.Name.ToUpper() == RoomName.ToUpper())
          {
            return room.Clone();
          }
        }
      }
      return null;
    }

    public bool AddUserToRoom(ChatUser User, ChatRoom Room)
    {
      lock (syncLock)
      {
        foreach (ChatRoom item in ChatRooms)
        {
          if (item.RoomID == Room.RoomID)
          {
            if (item.UserList.IndexOf(User.UserId) != -1) { return false; }
            item.UserList.Add(User.UserId);
            return true;
          }
        }
      }
      return false;
    }

    public bool RemoveUserFromRoom(ChatUser User, ChatRoom Room)
    {
      lock (syncLock)
      {
        foreach (ChatRoom item in ChatRooms)
        {
          if (item.RoomID == Room.RoomID)
          {
            if (item.UserList.IndexOf(User.UserId) == -1) { return false; }
            item.UserList.Remove(User.UserId);
            return true;
          }
        }
      }
      return false;
    }

    public bool UserInRoom(ChatUser User, ChatRoom Room)
    {
      lock (syncLock)
      {
        foreach (ChatRoom item in ChatRooms)
        {
          if (item.RoomID == Room.RoomID)
          {
            return (item.UserList.IndexOf(User.UserId) != -1);
          }
        }
      }
      return false;
    }

    public PoshBotTestServer.Common.RoomList RoomList()
    {
      PoshBotTestServer.Common.RoomList roomList = new PoshBotTestServer.Common.RoomList();
      lock (syncLock)
      {
        foreach(ChatRoom room in ChatRooms)
        {
          roomList.Add(room.Clone());
        }
      }
      return roomList;
    }

    public ChatStore()
    {
      if (ChatRooms.Count == 0)
      {
        ChatRoom Lobby = new ChatRoom();
        Lobby.Name = "Lobby";
        Lobby.Title = "Lobby Room";
        Lobby.RoomID = 0;
        ChatRooms.Add(Lobby);
      }
    }
  }
}
