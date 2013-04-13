part of irc_client;

/**
 * Constants for error commands codes.
 */
class Errors {
  static const NO_NICKNAME_GIVEN = 431;
  static const NICKNAME_IN_USE = 433;
  static const NOT_REGISTERED = 451;
}

/**
 * Constants for reply command codes.
 */
class Replies {
  static const L_USER_CLIENT = 251;
  static const L_USER_OP = 252;
  static const L_USER_UNKNOWN = 253;
  static const L_USER_CHANNELS = 254;
  static const L_USER_ME = 255;
  static const MOTD_START = 375;
  static const MOTD = 372;
  static const END_OF_MOTD = 376;
  static const NAME_REPLY = 353;
  static const END_OF_NAMES = 366;
}

/**
 * Constants for commands strings.
 */
class Commands {
  static const NOTICE = "NOTICE";
  static const PRIVMSG = "PRIVMSG";
  static const USER = "USER";
  static const NICK = "NICK";
  static const PING = "PING";
  static const PONG = "PONG";
  static const JOIN = "JOIN";
}

