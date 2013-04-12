part of irc_client;

class Command {
  String prefix;
  String command;
  List<String> params;
  String line;
  String trailing;
  
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
  
  int get commandNumber {
    try {
      return int.parse(command);
    } on FormatException catch (e) {
      return -1;
    }
  }
}



