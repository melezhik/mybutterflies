use IRC::Client;
use lib "lib";
use MyButterfly::Conf;
use MyButterfly::Utils;

class ButterflyBot does IRC::Client::Plugin {
    method irc-connected ($) {
        react {
          my @messages;
          for dir("{cache-root()}/bots/butterflieble/notifications/inbox") -> $m {
            my %meta = message-from-file($m);
            #unlink $m;
            say "unlink $m";
            push @messages, %meta;
          }
          whenever self!messages<> -> $m {
            say "handle message for bot: {$m.perl}";
            my $text = "mybfio: {$m<project>} has a new comment - https://mybf.io/{$m<link>}";
            say "send message to irc channel: <{$text}> ...";
            $.irc.send: :where<#melezhik-test> :text($text);
            say "unlink {$m<file>.basename} ...";
            unlink $m<file>;
          }
        }
    }

    method !messages {
        supply {
            loop {
                my @messages;
                for dir("{cache-root()}/bots/butterflieble/notifications/inbox") -> $m {
                  my %meta = message-from-file($m);
                  if grep "Raku" , %meta<project-meta><language><> {
                    emit %meta
                  }
                }
                sleep 10;
            }
        }
    }
}

.run with IRC::Client.new:
    :nick<Bitterflieable>
    :host<irc.libera.chat>
    :channels<#melezhik-test>
    #:debug
    :plugins(ButterflyBot.new)
