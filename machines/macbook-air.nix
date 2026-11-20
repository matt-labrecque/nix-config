let
  hostname = "MattBook";
in
{
  networking.hostName = hostname;
  networking.localHostName = hostname;
  networking.computerName = hostname;
}
