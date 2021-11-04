use IRC::Client;
use lib "lib";
use MyButterfly::Conf;
use MyButterfly::Utils;

my %stat;
my $channel = "#raku";

#my $channel = "#melezhik-test";
#my $channel = "#bottest1000";

class ButterflyBot does IRC::Client::Plugin {
    method irc-connected ($) {
        react {
          my @messages;
          for dir("{cache-root()}/bots/butterflieble/notifications/inbox") -> $m {
            my %meta = message-from-file($m);
            push @messages, %meta;
          }
          whenever self!messages<> -> $m {
            say "handle message for bot: {$m.perl}";
            my $text = "mybfio: {$m<project>} has a new comment - https://mybf.io/{$m<link>}";
            say "send message to irc channel: <{$text}> ...";
            $.irc.send: :where($channel) :text($text);
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
                    my $time-lapsed-in-hour = (now - INIT now) < 60*60 ?? 1 !! Int(now - INIT now);
                    if %stat{%meta<from>} && Int(%stat{%meta<from>} / $time-lapsed-in-hour) >= 5 {
                      say "throttling user {%meta<from>} ... more then 5 messages per hour";
                    } else {
                      %stat{%meta<from>}++;
                      emit %meta;
                    }
                  }
                }
                sleep 10;
            }
        }
    }
}

say %*ENV<LIBERA_SASL_PASSWORD>;
say "=====";

.run with IRC::Client.new:
    #:userhost<mybf.io>
    :port(5555)
    #:ssl(True)
    #:ca-file("./libera.pem")
    :nick<mybf>
    :username<znc>
    :password(%*ENV<ZTC_PASSWORD>)
    :host<127.0.0.1>
    #:channels($channel)
    :debug
    :plugins(ButterflyBot.new)
