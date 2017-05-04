using System;

namespace PoshBotTestServer
{
  namespace Common
  {
    public enum MessageType
    {
      ChannelRenamed,
      Message,
      PinAdded,
      PinRemoved,
      PresenceChange,
      ReactionAdded,
      ReactionRemoved,
      StarAdded,
      StarRemoved,
    }

    public enum MessageSubtype
    {
      None,
      ChannelJoined,
      ChannelLeft,
      ChannelRenamed,
      ChannelPurposeChanged,
      ChannelTopicChanged,
    }

    public class Message
    {
      public String Id;
      public MessageType Type = MessageType.Message;
      public MessageSubtype Subtype = MessageSubtype.None;
      public String FromUsername;
      public Int32 FromUserId;
      public String ToUsername;
      public Int32 ToUserId;
      public String ChannelId;
      public String ChannelName;
      public String Text;
      public DateTime TimeStamp;
    }

    public class User
    {
      public String Username;
      public Int32 UserId;
    }

    public class Room
    {
      public String Name;
      public String Title;
      public Int32 RoomID;
    }

    public class RoomList : System.Collections.Generic.List<Room> { }
  }
}
