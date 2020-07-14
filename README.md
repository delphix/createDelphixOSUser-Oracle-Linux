## createDelphixOSUser-Oracle-Linux
Bash Script for getting an Oracle Source or Target ready for Delphix

### Table of Contents
1. [Usage](#usage)
2. [How to Contribute](#contribute)
3. [Statement of Support](#statement-of-support)
4. [License](#license)

### <a id="usage"></a>Usage

Usage: $0 -t source|target [ -a key|passwd ] [ -u ] [ -k ] [ -s ] [ -q ] username 

  username : the user to create/modify.  REQUIRED PARAMETER

  -t : Type <source or target>.  REQUIRED PARAMETER

  -u : Create User. Will create the username.  Default is to modify an existing user. OPTIONAL

  -a : Auth Type <key or passwd>. OPTIONAL
       key: Add SSH Public Key for Delphix Engine to authorized_keys for the user.
       passwd: Add a password using the passwd utility.  Not compatible with quiet mode
       If you don't do either one, you'll be left with a user that cannot login, but you could su as root.

  -s : sudo privs. OPTIONAL
       Delphix targets require some kind of elevated privilege
       Delphix sources only require elevated privilege if you use a non default TNS_ADMIN
       If you don't use sudo for privilege elevation, you must use Privilege Elevation Profiles which isn't covered by this script.

  -k : kernel parameters. This only works for targets.  Highly Recommended for Delphix Targets. OPTIONAL

  -q : Quiet.  Automatically says Y to all prompts and accepts defaults.  Specify -q for full automation. OPTIONAL

  Examples:
  Create user delphix for a source environment with key authentication:  createDelphixOSUser.sh -t source -u -a key delphix

  Create user delphix for a target environment with password authentication:  createDelphixOSUser.sh -t target -u -a passwd delphix

  Create user delphix for a source, with key auth, sudo privs, and kernel parameter changes:  createDelphixOSUser.sh -t target -u -a key -s -k delphix

  Same as above with no interaction for full automation:  createDelphixOSUser.sh -t target -u -a key -s -k -q delphix

### <a id="contribute"></a>How to Contribute

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) to understand the pull requests process.

### <a id="statement-of-support"></a>Statement of Support

This software is provided as-is, without warranty of any kind or commercial support through Delphix. See the associated license for additional details. Questions, issues, feature requests, and contributions should be directed to the community as outlined in the [Delphix Community Guidelines](https://delphix.github.io/community-guidelines.html).

### <a id="license"></a>License

This is code is licensed under the Apache License 2.0. Full license is available [here](./LICENSE).
