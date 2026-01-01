#!/usr/bin/env python3
import os
import re
import sys
import argparse
import subprocess
from datetime import datetime

# --- Configuration ---
README_FILES = ["README.md", "README_DE.md", "README_UA.md"]
CHANGELOG_FILE = "CHANGELOG.md"
REMOTE_HOST = "root@lemue-sec"
REMOTE_DIR = "/root/honey-scan"
REMOTE_COMMANDS = (
    f"cd {REMOTE_DIR} && "
    "git pull && "
    "docker compose down && "
    "docker compose up -d --build && "
    "docker system prune -f"
)

def run_command(cmd, dry_run=False, cwd=None):
    """Executes a shell command."""
    if dry_run:
        print(f"[DRY-RUN] Executing: {cmd} (CWD: {cwd or 'Current'})")
        return 0, ""
    
    try:
        result = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=cwd
        )
        return result.returncode, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {cmd}")
        print(e.stderr)
        return e.returncode, e.stderr

def get_current_version(readme_path="README.md"):
    """Extracts version from the main README badge."""
    if not os.path.exists(readme_path):
        print(f"Error: {readme_path} not found.")
        sys.exit(1)
        
    with open(readme_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Regex for ![Version](https://img.shields.io/badge/version-X.Y.Z-blue.svg)
    match = re.search(r"!\[Version\]\(https://img\.shields\.io/badge/version-(\d+\.\d+\.\d+)-blue\.svg\)", content)
    if match:
        return match.group(1)
    else:
        print("Error: Could not find version badge in README.md")
        sys.exit(1)

def increment_version(version, part="patch"):
    """Increments the version string based on the part (major, minor, patch)."""
    major, minor, patch = map(int, version.split('.'))
    
    if part == "major":
        major += 1
        minor = 0
        patch = 0
    elif part == "minor":
        minor += 1
        patch = 0
    else: # patch
        patch += 1
        
    return f"{major}.{minor}.{patch}"

def update_readmes(new_version, dry_run=False):
    """Updates the version badge in all README files."""
    for readme in README_FILES:
        if not os.path.exists(readme):
            print(f"Warning: {readme} not found, skipping.")
            continue
            
        print(f"Updating {readme} to version {new_version}...")
        if dry_run:
            continue

        with open(readme, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace version based on generic regex to catch desynced versions too
        new_content = re.sub(
            r"!\[Version\]\(https://img\.shields\.io/badge/version-\d+\.\d+\.\d+-blue\.svg\)",
            f"![Version](https://img.shields.io/badge/version-{new_version}-blue.svg)",
            content
        )
        
        with open(readme, "w", encoding="utf-8") as f:
            f.write(new_content)

def update_changelog(new_version, dry_run=False):
    """Prepends the new version header to CHANGELOG.md."""
    if not os.path.exists(CHANGELOG_FILE):
        print(f"Error: {CHANGELOG_FILE} not found.")
        return

    print(f"Updating {CHANGELOG_FILE} for v{new_version}...")
    
    date_str = datetime.now().strftime("%Y-%m-%d")
    header = f"## [{new_version}] - {date_str}\n\n### Changed\n- 🚀 **Auto-Deploy**: Automated release via protocol.\n\n"
    
    if dry_run:
        print(f"[DRY-RUN] Would inject header:\n{header}")
        return

    with open(CHANGELOG_FILE, "r", encoding="utf-8") as f:
        content = f.readlines()
        
    # Find the line after "## [Unreleased]" or just after the header if no unreleased
    # Assuming standard format, we insert after "All notable changes..."
    
    insert_idx = 0
    for i, line in enumerate(content):
        if "All notable changes to this project" in line:
            insert_idx = i + 2 # Skip blank line
            break
            
    if insert_idx == 0 and len(content) > 5:
        insert_idx = 4 # Fallback
        
    content.insert(insert_idx, header)
    
    with open(CHANGELOG_FILE, "w", encoding="utf-8") as f:
        f.writelines(content)

def security_audit(dry_run=False):
    """Scans for secrets and manages .env.example."""
    print("Performing Security Audit...")
    
    # Check .gitignore for .env
    if os.path.exists(".gitignore"):
        with open(".gitignore", "r") as f:
            if ".env" not in f.read():
                print("SECURITY WARNING: .env not found in .gitignore!")
                if not dry_run:
                    with open(".gitignore", "a") as af:
                        af.write("\n.env\n")
                    print("Added .env to .gitignore")
    
    # Ensure .env.example exists
    if not os.path.exists(".env.example"):
        print("Creating .env.example...")
        if not dry_run:
            with open(".env.example", "w") as f:
                f.write("# Database Configuration\nDB_PASSWORD=secret\nMYSQL_ROOT_PASSWORD=secret\n")
    
    # Simple scan for secrets in tracked files (grep for 'password=' or similar could be added here)
    # For now, just ensuring .env is not tracked is the main check.
    # We can check if .env is currently tracked by git
    rc, out = run_command("git ls-files .env", dry_run=False) # Always check specific git status
    if out == ".env":
        print("CRITICAL: .env is being tracked by git! Please remove it from cache.")
        if not dry_run:
             run_command("git rm --cached .env")
             print("Removed .env from git info.")

def main():
    parser = argparse.ArgumentParser(description="Auto-Deploy Script for Honey-Scan")
    parser.add_argument("--dry-run", action="store_true", help="Simulate execution")
    parser.add_argument("--major", action="store_true", help="Increment Major version")
    parser.add_argument("--minor", action="store_true", help="Increment Minor version")
    parser.add_argument("--msg", type=str, default="Auto update", help="Commit message description")
    
    args = parser.parse_args()
    
    # 1. Determine Version
    current_ver = get_current_version()
    print(f"Current Version: {current_ver}")
    
    part = "patch"
    if args.major: part = "major"
    elif args.minor: part = "minor"
    
    new_ver = increment_version(current_ver, part)
    print(f"Target Version:  {new_ver}")
    
    # 2. Update Docs
    update_readmes(new_ver, args.dry_run)
    update_changelog(new_ver, args.dry_run)
    
    # 3. Security Audit
    security_audit(args.dry_run)
    
    # 4. Deployment
    commit_msg = f"Auto-Deploy v{new_ver}: {args.msg}"
    
    print("\n--- Git Operations ---")
    run_command("git add .", args.dry_run)
    run_command(f'git commit -m "{commit_msg}"', args.dry_run)
    run_command("git push", args.dry_run)
    
    print("\n--- Remote Deployment ---")
    ssh_cmd = f'ssh {REMOTE_HOST} "{REMOTE_COMMANDS}"'
    run_command(ssh_cmd, args.dry_run)
    
    print("\nDone.")

if __name__ == "__main__":
    main()
