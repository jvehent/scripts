#! /usr/bin/perl -w
use strict;
# julien vehent - oct. 2009
# browse a list of folder and change the permission
# according to a defined list of patterns and perms

# perm_list contain pattern + associated chmod perm (user|group|others)
# the first pattern that matches is the one applied
# "default" is mandatory and applied when no pattern match the entry
#
my %perm_list = ( 
                  "prv" => "770", 
                  "default"=> "775" 
                );

my $verbose = 0;

sub check_recursively
{
   my $folder_name = $_[0];

   print "entering $folder_name\n";

   # open folder and loop on each entry
   opendir my($folder), $folder_name or die "Couldn't open $folder_name: $!\n";

   for my $entry (readdir($folder))
   {
      if(($entry eq ".") or ($entry eq ".."))
      {
         next;
      }

      #print "$entry; ";

      my $entry_chmoded = 0;

      my $entry_full_path = $folder_name."/".$entry;

      # check entry with all patterns, except default
      foreach my $pattern (keys %perm_list)
      {
         # entry matches pattern, apply corresponding chmod and mark entry
         if (($entry =~ /$pattern/) and ($pattern ne "default"))
         {
            print "$pattern matches -> chmod $perm_list{$pattern} $entry_full_path\n" if $verbose == 1;
            system("chmod $perm_list{$pattern} \"$entry_full_path\"");
            $entry_chmoded = 1;
         }
      }

      # entry didn't match any pattern, apply default permission
      if($entry_chmoded == 0)
      {
         print "default -> chmod $perm_list{'default'} $entry_full_path\n" if $verbose == 1;
         system("chmod $perm_list{'default'} \"$entry_full_path\"");
      }

      #if entry is a folder, go visit it
      if ((-d $entry_full_path) and ($entry ne ".") and ($entry ne ".."))
      {
         check_recursively($entry_full_path);
      }

   }
   closedir($folder);
}


#--- MAIN CODE ---
unless(defined @ARGV)
{
   print "\nchmod_selected_folders.pl\njve - oct.2009\n\nusage: ./chmod_selected_folders.pl <folder 1> ... <folder n>\n\n";
}

print "using perm list:\n";
foreach my $pattern (keys %perm_list)
{
   print "  * pattern $pattern will be applied permission $perm_list{$pattern}\n";
}

# list of folder in stdin, loop on it
foreach my $folder_name (@ARGV)
{
   print "processing entries starting at $folder_name\n";

   check_recursively($folder_name);
}

