use IRC::Client;

class ButterflyBot does IRC::Client::Plugin {
    method irc-connected ($) {
        react {
            whenever Supply.interval(3) {
                $.irc.send: :where<#melezhik-test> :text<Test ButterflyBot>;
            }
        }
    }
}

.run with IRC::Client.new:
    :nick<Bitterflieable>
    :host<irc.libera.chat>
    :channels<#melezhik-test>
    :debug
    :plugins(ButterflyBot.new)
