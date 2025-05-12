# 🔐 Git SSH Setup Wizard

A fully interactive, secure Bash script to link your Git (GitHub, GitLab, Bitbucket, etc.) with SSH — no password prompts, no half-configs, no risk.


## 🧠 What It Does

- Generates a secure `ed25519` SSH key pair (if needed)
- Adds key to `ssh-agent`
- Outputs the public key to paste into Git provider
- (Optionally) updates `~/.ssh/config` for seamless Git use
- Validates all inputs and safely handles existing files
- Tests connection to confirm success


## 📦 Requirements

- Bash 4+ (Linux/macOS/WSL)
- OpenSSH tools installed: `ssh`, `ssh-keygen`, `ssh-agent`
- Git installed


## 🚀 Usage

```bash
chmod +x git_ssh_setup.sh
./git_ssh_setup.sh
````

Then follow the prompts:

* Enter your **email**
* Specify your **Git provider domain** (e.g. `github.com`)
* Optionally name the SSH key
* Copy/paste the generated **public key** into your Git host
* (Optional) Add an SSH config entry


## 🧪 Example

```bash
$ ./git_ssh_setup.sh

📧 Enter email for SSH key (used as label): dev@company.com
🌐 Git provider domain (e.g. github.com, gitlab.com): github.com
🔑 SSH key filename (default: id_ed25519):
...
📋 Copy and paste this public key into your Git provider
📝 Add it to: https://github.com/settings/ssh_keys
```


## 🛡️ Security

* Uses `ed25519` keys (smaller & stronger than RSA)
* Files are locked to `600` / `644` permission standards
* SSH agent is used for passphrase protection
* Prevents duplicate SSH config or key conflicts


## 📁 Output Files

| File                    | Description                  |
| ----------------------- | ---------------------------- |
| `~/.ssh/id_ed25519`     | Private SSH key              |
| `~/.ssh/id_ed25519.pub` | Public SSH key to add to Git |
| `~/.ssh/config`         | SSH host alias config        |


## 🧯 Troubleshooting

* **Permission denied** – Make sure key is added to Git host and in agent
* **ssh-agent not running** – Restart terminal or manually run `eval "$(ssh-agent -s)"`
* **Config conflicts** – Manually review `~/.ssh/config`


## 🤖 Use in CI/CD

To use SSH in automated pipelines:

1. Generate a **deploy key** using this script.
2. Add the **public key** to the repo as a **read-only deploy key**.
3. Use the **private key** as a secret in your pipeline runner.
4. Load the key during build and configure `ssh-agent`.


## 📎 License

MIT – Use freely, improve safely.


## 🧰 Related Tools

* [`ssh-keygen`](https://man.openbsd.org/ssh-keygen)
* [`ssh-agent`](https://linux.die.net/man/1/ssh-agent)
* GitHub SSH Docs: [https://docs.github.com/en/authentication/connecting-to-github-with-ssh](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

