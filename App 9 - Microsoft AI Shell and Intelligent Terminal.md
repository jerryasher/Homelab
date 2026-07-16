# App 9 - Microsoft Intelligent Terminal

#### WRITTEN: 2026 July 16

## SUMMARY

Intelligent Terminal is best viewed as an AI-aware terminal rather
than an AI coding environment.

Its greatest value for my workflow is reducing the friction of
investigating terminal problems by allowing an AI agent to directly
understand command history, logs, errors, and terminal output without
manual copy and paste.

+ how to install and configure them
+ how to use them with **free or low‑cost 
+ how to obtain API keys
+ how to connect them to **Ollama over a local network** with
  recommended models.


+ https://github.com/microsoft/intelligent-terminal
+ https://devblogs.microsoft.com/commandline/announcing-intelligent-terminal-version-0-1/

---

## Why Use It?

For my workflow, Intelligent Terminal is primarily useful as an intelligent assistant for command-line work rather than as a full coding agent.

Good use cases:

* Explain why a command failed.
* Summarize compiler or interpreter errors.
* Search and summarize large log files.
* Explain shell commands.
* Suggest PowerShell, Bash, or Ansible commands.
* Understand the context of the current terminal session without copy/paste.

Examples:

```text
Why did this ansible-playbook fail?

Find the first error in this log.

Summarize today's Git activity.

Explain this ffmpeg command.

Show me the three distinct exceptions in this log.
```

The major advantage is that the agent already has access (subject to permissions) to:

* current working directory
* recent command history
* terminal output
* stderr/stdout
* current session context

That eliminates constantly copying terminal output into ChatGPT.

Best for:

- Python development  
- Web development  
- Android development  
- DevOps / Ansible  
- Multi-shell workflows  
- Log-heavy tasks  

---

## 2. Installation & Setup

Search: **Intelligent Terminal** → Install

#### WinGet

```powershell
winget install --id Microsoft.IntelligentTerminal -e
```

On first launch:

- It auto-detects agents  
- Installs GitHub Copilot CLI if needed  
- Walks you through sign-in  

---

## 3. Free / Low-Cost LLM Backends


### GitHub Copilot CLI (Free Tier)

- Works out of the box with Intelligent Terminal  
- Free tier is generous  
* OAuth authentication.
- Good for command generation, error explanation  

### Google Gemini (Free Tier)

* OAuth authentication.
- Gemini 2.0 Flash is fast and free  
- Great for shell translation, log analysis  
- Works via Gemini CLI or custom ACP wrapper


---

## 4. Getting API Keys if Oauth is not available

### GitHub Copilot CLI

1. Install Copilot CLI  
2. Run:
   
   ```bash
   gh auth login
   gh copilot setup
   ```
3. No API key required — uses GitHub auth.

### Anthropic Claude

1. Go to [https://console.anthropic.com](https://console.anthropic.com)  
2. Create account  
3. Free tier includes Claude 3.5 Sonnet  
4. Copy API key from “API Keys” section

### Google Gemini

1. Go to [https://aistudio.google.com](https://aistudio.google.com)  
2. Create account  
3. Generate API key  
4. Use with Gemini CLI or custom agent

### OpenAI GPT‑4o mini

1. Go to [https://platform.openai.com](https://platform.openai.com)  
2. Create account  
3. Generate API key  
4. Set usage limits to avoid surprise charges

---

## 5. Connecting to Ollama Over a Network

Intelligent Terminal can use a custom agent that forwards prompts to Ollama running on another machine.

### Ollama Network Setup

On the machine running Ollama:

```bash
ollama serve --address 0.0.0.0:11434
```

Ensure firewall allows inbound TCP 11434.

### Custom ACP Agent (Intelligent Terminal)

Create a small script that:

- Accepts ACP JSON  
- Sends prompt to Ollama via HTTP  
- Returns model output in ACP format

Example request:

```bash
curl http://<ollama-host>:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Explain this error..."
}'
```

---

## 6. Recommended Ollama Models

### For PowerShell / Windows Admin

- **Phi-3 mini** (fast, small, good reasoning)
- **Llama 3.1 8B** (best balance of speed + quality)

### For Python / Web Dev

- **Llama 3.1 8B**  
- **Gemma 2 9B** (excellent code reasoning)

### For Android / DevOps

- **Llama 3.1 8B**  
- **Qwen 2.5 7B** (strong log analysis)

### For Shell Translation (Bash → PowerShell)

- **Phi-3 medium**  
- **Llama 3.1 8B**  

### For general-purpose reasoning

- **Llama 3.1 8B**  
- **Gemma 2 9B**  

## 7. Switching Providers

One of the major goals of Intelligent Terminal is making provider switching simple.

Instead of reconfiguring the terminal, install multiple compatible agents.

Example:

```text
Morning
    GitHub Copilot

Free quota exhausted

Switch active agent

    Gemini

Need local/private processing

Switch active agent

    Ollama
```

