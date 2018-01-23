Create HathiTrust EPUB SIP from EPUB

## Installation

```bash
git clone https://github.com/hathitrust/epub_sip
cd epub_sip
bundle install
bundle exec rspec
```

## Generating SIPs

Say we have a directory full of epubs in `epub_sip/test_epub` and we want to create SIPs in `epub_sip/test_output`:

```bash
mkdir test_output
cd test_output
for file in ../test_epub/*epub; do echo $file; be ruby ../bin/epub_sip $(basename $file .epub) creation_agent $file; done
```

Then we can extract the generated meta.yml files:

```bash
for file in *zip; do unzip -d $(basename $file .zip) $file meta.yml; done
```
