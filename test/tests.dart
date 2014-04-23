library irc_client;

import 'package:unittest/unittest.dart';
import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';

part '../lib/src/constants.dart';
part '../lib/src/connection.dart';
part '../lib/src/command.dart';
part '../lib/src/handler.dart';
part '../lib/src/nickserv.dart';
part '../lib/src/client.dart';

/**
 * Mock Socket class implementing just what we do use from Socket
 */
class Socket {
  StringBuffer sb;

  Socket() {
    sb = new StringBuffer();
  }

  void writeln(Object obj) => sb.writeln(obj);
  Future<Socket> close() => new Future.value(this);
  static Future<Socket> connect(host, int port) => new Future.value(new Socket());
}

main() {
  group('Command', () {
    test('should recognise prefix', () {
      var cmd = new Command(":prefix more stuff");
      expect(cmd.prefix, equals("prefix"));
    });
    
    test('should have empty prefix if missing', () {
      var cmd = new Command("just stuff");
      expect(cmd.prefix, equals(null));
    });
    
    test('should have empty prefix if empty command', () {
      var cmd = new Command("");
      expect(cmd.prefix, equals(null));
    });
    
    test('should have prefix if empty command with prefix', () {
      var cmd = new Command(":prefix");
      expect(cmd.prefix, equals("prefix"));
    });
    
    test('should have prefix if empty command with prefix and space', () {
      var cmd = new Command(":prefix ");
      expect(cmd.prefix, equals("prefix"));
    });
    
    test('should have empty prefix just space', () {
      var cmd = new Command(" ");
      expect(cmd.prefix, equals(null));
    });
    
    test('should have empty prefix just spaces', () {
      var cmd = new Command("     ");
      expect(cmd.prefix, equals(null));
    });
    
    test('should have prefix if empty command with prefix and spaces', () {
      var cmd = new Command(":prefix    ");
      expect(cmd.prefix, equals("prefix"));
    });
    
    test('should have command when prefixed', () {
      var cmd = new Command(":prefix command");
      expect(cmd.command, equals("command"));
    });
    
    test('should have command when not prefixed', () {
      var cmd = new Command("command");
      expect(cmd.command, equals("command"));
    });
    
    test('should have params', () {
      var cmd = new Command(":prefix command p1 p2 p3");
      expect(cmd.params.length, equals(3));
    });
    
    test('should have params', () {
      var cmd = new Command(":prefix command p1 p2 p3");
      expect(cmd.params[1], equals("p2"));
    });
    
    test('should have params when not prefixed', () {
      var cmd = new Command("command p1 p2 p3");
      expect(cmd.params[1], equals("p2"));
    });
    
    test('should have trailing stuff', () {
      var cmd = new Command("command p1 p2 p3 :this is trailing");
      expect(cmd.trailing, equals("this is trailing"));
    });
    
    test('should have trailing stuff with prefix', () {
      var cmd = new Command(":prefix command p1 p2 p3 :this is trailing");
      expect(cmd.trailing, equals("this is trailing"));
    });
    
    test('should have trailing stuff with prefix without colon', () {
      var cmd = new Command(":prefix command p1 p2 p3 trailing");
      expect(cmd.trailing, equals("trailing"));
    });
  });
  
  group('namesAreEqual', () {
    test('should think {==[', () {
      expect(namesAreEqual("{", "["), isTrue);
    });

    test('should think }==]', () {
      expect(namesAreEqual("}", "]"), isTrue);
    });

    test(r'should think |==\', () {
      expect(namesAreEqual("|", r"\"), isTrue);
    });

    test('should think ^==~', () {
      expect(namesAreEqual("^", "~"), isTrue);
    });

    test(r'should think JAMES[]\~==james{}|^', () {
      expect(namesAreEqual(r"JAMES[]\~", "james{}|^"), isTrue);
    });
  });
  
  group('isChannel', () {
    test('should recognise channel starting with #', () {
      expect(isChannel("#thing"), isTrue);
    });

    test('should recognise channel starting with &', () {
      expect(isChannel("&thing"), isTrue);
    });

    test('should recognise channel starting with +', () {
      expect(isChannel("+thing"), isTrue);
    });

    test('should recognise channel starting with !', () {
      expect(isChannel("!thing"), isTrue);
    });


    test('should not recognise non-channels', () {
      expect(isChannel("thing"), isFalse);
      expect(isChannel("thing+"), isFalse);
      expect(isChannel("thi#ng"), isFalse);
      expect(isChannel("th#ing"), isFalse);
      expect(isChannel("t###"), isFalse);
    });
  });
  
  group('Irc', () {
    var socket;
    var cnx;
    
    setUp(() {
      socket = new Socket();
      cnx = new Connection._(null, null, null, null, new List<Handler>());
      cnx._socket = socket;
    });
    
    test('should write', () {
      cnx.write("hello");
      expect(socket.sb.toString(), equals("hello\n"));
    });

    test('should send message', () {
      cnx.sendMessage("person", "message");
      expect(socket.sb.toString(), equals("PRIVMSG person :message\n"));
    });

    test('should send notice', () {
      cnx.sendNotice("person", "notice");
      expect(socket.sb.toString(), equals("NOTICE person :notice\n"));
    });

    test('should join channel', () {
      cnx.join("#channel");
      expect(socket.sb.toString(), equals("JOIN #channel\n"));
    });

    test('should set nick', () {
      expect(cnx.nick, isNull);
      cnx.setNick("bob");
      expect(socket.sb.toString(), equals("NICK bob\n"));
      expect(cnx.nick, equals("bob"));
    });
  });
}
