unit module MyButterfly::User;

use MyButterfly::HTML;

sub gen-token is export {

  ("a".."z","A".."Z",0..9).flat.roll(8).join

}


sub check-user ($user, $token) is export {

  return False unless $user;

  return False unless $token;

  return "{cache-root()}/users/{$user}/tokens/{$token}".IO ~ :e

}
