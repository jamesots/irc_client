part of irc_client;

/**
 * Contains a command which was received from the IRC server.
 */
class Command {
  /**
   * The prefix without the leading colon (:), or null if there was not one.
   */
  String prefix;
  
  /**
   * The command.
   */
  String command;
  
  /**
   * A list of the parameters, including the trailing parameters.
   */
  List<String> params;
  
  /**
   * Contains the original line received from the server.
   */
  String line;
  
  /**
   * Any trailing text, without its leading colon (:). The trailing text
   * is all the text from the first parameter which starts with a colon 
   * up to the end of the line, or if there is no colon-prefixed parameter,
   * the last paramter. 
   */
  String trailing;
  
  /**
   * Parses a line from the server into a [Command] object.
   */
  Command(String line) {
    this.line = line;
    
    var bits = line.split(" ");
    var bit = 0;
    var charIndex = 0;
    if (line.startsWith(":")) {
      prefix = bits[bit].substring(1);
      bit++;
      charIndex += prefix.length + 1;
    }
    
    if (bits.length > bit) {
      command = bits[bit];
      charIndex += command.length + 1;
      
      params = bits.sublist(bit + 1);
      
      if (params.length > 0) {
        var startOfTrailing = line.indexOf(" :", charIndex);
        if (startOfTrailing != -1) {
          trailing = line.substring(startOfTrailing + 2);
        } else {
          trailing = params[params.length - 1];
        }
      }
    }
  }
  
  /**
   * Returns the command number or, if the command was not numberic,
   * returns -1.
   */
  int get commandNumber {
    try {
      return int.parse(command);
    } on FormatException catch (e) {
      return -1;
    }
  }
}



