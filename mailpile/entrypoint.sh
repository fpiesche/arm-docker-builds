#!/bin/bash

echo "Downloading Mailpile version $MAILPILE_VERSION..."
git clone https://github.com/mailpile/Mailpile.git --branch $MAILPILE_VERSION --single-branch --depth=1

echo "Installing Mailpile requirements..."
pip install -r /Mailpile/requirements.txt

if [[ ! -f /root/.local/share/Mailpile/default/mailpile.cfg ]]; then
    echo "Running initial Mailpile setup..."
    /Mailpile/mp setup | cat
fi

echo "Launching Mailpile."
/Mailpile/mp --www=0.0.0.0:33411 --wait
