library irc_client;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';

part '../lib/src/constants.dart';
part '../lib/src/connection.dart';
part '../lib/src/command.dart';
part '../lib/src/handler.dart';
part '../lib/src/nickserv.dart';
part '../lib/src/client.dart';

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
    var sb;
    
    setUp(() {
      sb = new StringBuffer();
      socket = new MockSocket();
      socket.when(callsTo('writeln')).alwaysCall(sb.writeln);
      cnx = new Connection._(null, null, null, null, new List<Handler>());
      cnx._socket = socket;
    });
    
    test('should write', () {
      cnx.write("hello");
      expect(sb.toString(), equals("hello\n"));
    });

    test('should send message', () {
      cnx.sendMessage("person", "message");
      expect(sb.toString(), equals("PRIVMSG person :message\n"));
    });

    test('should send notice', () {
      cnx.sendNotice("person", "notice");
      expect(sb.toString(), equals("NOTICE person :notice\n"));
    });

    test('should join channel', () {
      cnx.join("#channel");
      expect(sb.toString(), equals("JOIN #channel\n"));
    });

    test('should set nick', () {
      expect(cnx.nick, isNull);
      cnx.setNick("bob");
      expect(sb.toString(), equals("NICK bob\n"));
      expect(cnx.nick, equals("bob"));
    });

    test('should split messages on last whitespace if > LIMIT_MESSAGE_SIZE', () {
      var command = "CMD person";
      var message1 = new StringBuffer(), message2 = new StringBuffer("bbbbb"),
          message3 = new StringBuffer();
      for (var i = 0; i < MAX_MESSAGE_SIZE - 10; i++) {
        message1.write("a");
      }
      for (var i = 0; i < 20; i++) {
        message3.write("c");
      }
      cnx.splitAndWrite(command, "${message1.toString()} ${message2.toString()} ${message3.toString()}");
      var socketWriteLogs = socket.getLogs(callsTo('writeln'))
          ..verify(happenedExactly(2));
      expect(socketWriteLogs.logs[0].args, equals(["$command :${message1.toString()} ${message2.toString()}"]));
      expect(socketWriteLogs.logs[1].args, equals(["$command :${message3.toString()}"]));
    });

    test('should split messages that are > LIMIT_MESSAGE_SIZE  without spaces in multiple requests', () {
      var command = "CMD person";
      var messagePart1 = new StringBuffer(), messagePart2 = new StringBuffer(), messagePart3 = new StringBuffer();
      for (var i = 0; i < MAX_MESSAGE_SIZE; i++) {
        messagePart1.write("a");
        messagePart2.write("b");
        messagePart3.write("c");
      }
      cnx.splitAndWrite(command,
          "${messagePart1.toString()}${messagePart2.toString()}${messagePart3.toString()}");
      var socketWriteLogs = socket.getLogs(callsTo('writeln'))
          ..verify(happenedExactly(3));
      expect(socketWriteLogs.logs[0].args, equals(["$command :${messagePart1.toString()}"]));
      expect(socketWriteLogs.logs[1].args, equals(["$command :${messagePart2.toString()}"]));
      expect(socketWriteLogs.logs[2].args, equals(["$command :${messagePart3.toString()}"]));
    });

    test('should split existing messages on whitespace, and let the following one > LIMIT_MESSAGE_SIZE '
         'without spaces on its own requests', () {
      var command = "CMD person";
      var message1 = new StringBuffer("aaaa"), message2Part1 = new StringBuffer(),
          message2Part2 = new StringBuffer("bbbbb"), message3 = new StringBuffer("ccccc");
      for (var i = 0; i < MAX_MESSAGE_SIZE; i++) {
        message2Part1.write("b");
      }
      cnx.splitAndWrite(command, "${message1.toString()} ${message2Part1.toString()}${message2Part2.toString()} "
                                 "${message3.toString()}");
      var socketWriteLogs = socket.getLogs(callsTo('writeln'))
          ..verify(happenedExactly(3));
      expect(socketWriteLogs.logs[0].args, equals(["$command :${message1.toString()}"]));
      expect(socketWriteLogs.logs[1].args, equals(["$command :${message2Part1.toString()}"]));
      expect(socketWriteLogs.logs[2].args, equals(["$command :${message2Part2.toString()} ${message3.toString()}"]));
    });

    test('should close properly, returning the socket', () {
      cnx._socket.when(callsTo('close')).thenReturn(new Future.value(cnx._socket));
      return cnx.close().then((value) {
        expect(value, equals(socket));
        socket.getLogs(callsTo('close')).verify(happenedOnce);
      });
    });

    test('throw if the socket was already closed', () {
      cnx._socket = null;
      return cnx.close().catchError((message) {
        expect(message, new isInstanceOf<String>());
      });
    });
  });
}

class MockSocket extends Mock implements Socket {}
