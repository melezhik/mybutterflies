unit module MyButterfly::User;

sub gen-token is export {

  ("a".."z","A".."Z",0..9).flat.roll(8).join

}
