# **Microsoft AI Shell and. Intelligent Terminal — Practical Guide for Real Development Work**

This document summarizes the strengths of **AI Shell** and **Intelligent Terminal**, how they differ across development tasks, how to install and configure them, how to use them with **free or low‑cost LLMs**, how to obtain API keys, and how to connect them to **Ollama over a network** with recommended models.

---

## **1. Overview**

### **AI Shell**
A PowerShell‑centric AI assistant that runs *inside* your existing shell.  
Best for:
- PowerShell scripting  
- Windows administration  
- Command generation  
- Error remediation  
- Azure workflows  

### **Intelligent Terminal**
A full terminal application (fork of Windows Terminal) with a native AI agent pane, background tasks, and ACP agent integration.  
Best for:
- Python development  
- Web development  
- Android development  
- DevOps / Ansible  
- Multi-shell workflows  
- Log-heavy tasks  

---

## **2. Strengths by Development Task**

### **PowerShell**
- **AI Shell excels**: deep PS integration, error remediation, command generation.
- Intelligent Terminal is helpful but generic.

### **Ansible**
- **Intelligent Terminal excels**: multi-shell workflows, SSH, WSL, long-running tasks, log ingestion.
- AI Shell is fine for YAML generation but not operational workflows.

### **Python**
- **Intelligent Terminal excels**: traceback analysis, multi-shell execution, background tasks.
- AI Shell is limited to simple command generation.

### **Web Development**
- **Intelligent Terminal excels**: build logs, server logs, npm/webpack output, multi-shell workflows.
- AI Shell is helpful but shallow.

### **Android Development**
- **Intelligent Terminal excels**: Gradle logs, ADB output, fastboot workflows, long-running builds.
- AI Shell is not suited for this domain.

---

## **3. Installation & Setup**

### **AI Shell Installation**
```powershell
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-aishell.ps1') }"
```

This installs:
- PowerShell 7.4.6+
- PSReadLine beta
- AI Shell (`aish`)
- Sidecar integration

Launch:
```powershell
Start-AIShell
```

### **Intelligent Terminal Installation**

#### **Microsoft Store (recommended)**
Search: **Intelligent Terminal** → Install

#### **WinGet**
```powershell
winget install --id Microsoft.IntelligentTerminal -e
```

On first launch:
- It auto-detects agents  
- Installs GitHub Copilot CLI if needed  
- Walks you through sign-in  

---

## **4. Free / Low-Cost LLM Backends**

Both AI Shell and Intelligent Terminal can use external LLMs. Intelligent Terminal uses ACP agents; AI Shell uses Azure/OpenAI endpoints.

### **GitHub Copilot CLI (Free Tier)**
- Works out of the box with Intelligent Terminal  
- Free tier is generous  
- Good for command generation, error explanation  

### **Anthropic Claude (Free Developer Tier)**
- Claude 3.5 Sonnet available for free  
- Excellent quality  
- Easy to wrap in a custom ACP agent  
- Best free option for dev workflows

### **Google Gemini (Free Tier)**
- Gemini 2.0 Flash is fast and free  
- Great for shell translation, log analysis  
- Works via Gemini CLI or custom ACP wrapper

### **OpenAI GPT‑4o mini (Ultra‑cheap)**
- ~$0.15 per million tokens  
- Good quality  
- Works with both tools  
- Best “almost free” option

---

## **5. Getting API Keys**

### **GitHub Copilot CLI**
1. Install Copilot CLI  
2. Run:
   ```bash
   gh auth login
   gh copilot setup
   ```
3. No API key required — uses GitHub auth.

### **Anthropic Claude**
1. Go to [https://console.anthropic.com](https://console.anthropic.com)  
2. Create account  
3. Free tier includes Claude 3.5 Sonnet  
4. Copy API key from “API Keys” section

### **Google Gemini**
1. Go to [https://aistudio.google.com](https://aistudio.google.com)  
2. Create account  
3. Generate API key  
4. Use with Gemini CLI or custom agent

### **OpenAI GPT‑4o mini**
1. Go to [https://platform.openai.com](https://platform.openai.com)  
2. Create account  
3. Generate API key  
4. Set usage limits to avoid surprise charges

---

## **6. Connecting to Ollama Over a Network**

Both AI Shell and Intelligent Terminal can use a custom agent that forwards prompts to Ollama running on another machine.

### **Ollama Network Setup**
On the machine running Ollama:
```bash
ollama serve --address 0.0.0.0:11434
```

Ensure firewall allows inbound TCP 11434.

### **Custom ACP Agent (Intelligent Terminal)**
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

### **AI Shell Custom Endpoint**
AI Shell supports custom endpoints via configuration:
```json
{
  "endpoint": "http://<ollama-host>:11434/api/generate",
  "model": "llama3.1:8b"
}
```

---

## **7. Recommended Ollama Models**

### **For PowerShell / Windows Admin**
- **Phi-3 mini** (fast, small, good reasoning)
- **Llama 3.1 8B** (best balance of speed + quality)

### **For Python / Web Dev**
- **Llama 3.1 8B**  
- **Gemma 2 9B** (excellent code reasoning)

### **For Android / DevOps**
- **Llama 3.1 8B**  
- **Qwen 2.5 7B** (strong log analysis)

### **For Shell Translation (Bash → PowerShell)**
- **Phi-3 medium**  
- **Llama 3.1 8B**  

### **For general-purpose reasoning**
- **Llama 3.1 8B**  
- **Gemma 2 9B**  

---

If you want, I can also generate a **full-length guide**, a **quick-start cheat sheet**, or a **step-by-step setup script** for your environment.
