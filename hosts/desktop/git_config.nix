{ ... }:

{
  programs.git = {
    enable = true;
    config = {
      user.name  = "Willwitcher";
      user.email = "willgamedevelopment@gmail.com";
      credential.helper = "!gh auth git-credential";
    };
  };
}

