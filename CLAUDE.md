# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a roadtrip planner application currently in its initial stages. The repository is licensed under the MIT License.

## Repository Status

The repository is currently empty except for README.md and LICENSE files. No technology stack or build system has been chosen yet.

## Development Notes

## System / Role
You are a senior Rails + DevOps engineer. Generate a brand-new Rails 8 application called **`roadtrip_planner`**, containerized with Docker Compose for development. It should run with **Docker only** (no host Ruby/Node required) and show a default page in the browser.

---

## Goal
Produce a fully working Rails 8.0.2.1 + Ruby 3.4 + Postgres 17 stack that boots with `docker compose up` and renders a page at `http://localhost:3000`.

---

## Requirements

1. **App Scaffold**  
   - Project name: `roadtrip_planner`  
   - Rails: `8.0.2.1`  
   - Ruby: `3.4.x`  
   - PostgreSQL: `17`  
   - JavaScript: **Importmap** (Rails default, no Node service required).  

2. **Files to Generate**  
   - `Dockerfile` → based on `ruby:3.4-slim`. Install build deps, add non-root user, run `bundle install`, expose port 3000, default `CMD` starts Puma.  
   - `docker-compose.yml` → services:  
     • `web`: builds Rails app, mounts code volume, uses bundle cache volume, depends on db (healthy).  
     • `db`: uses `postgres:17-alpine`, with env vars in `.env`.  
   - `.dockerignore` → ignore logs, tmp, node_modules, vendor/bundle, .git.  
   - `.env` → DB name, user, password, host.  
   - `Gemfile` → Rails `~> 8.0.2`, pg, puma, bootsnap, etc.  
   - `config/database.yml` → postgres adapter, env vars, host=db.  
   - `bin/docker-entrypoint` → wait for db (`pg_isready`), `bundle check || bundle install`, `bin/rails db:prepare`, then `exec "$@"`.  
   - `Makefile` (optional) with targets `build`, `up`, `down`, `logs`, `bash`, `reset-db`.  

3. **Rails Initialization**  
   - Scaffold with `rails new roadtrip_planner --database=postgresql` (accept defaults for JS = importmap).  
   - Add a simple `PagesController#home`, root route to `home`, and a view that displays “Hello from roadtrip_planner!”.  

4. **Instructions Section**  
   - Show how to build and run:  
     ```bash
     docker compose build
     docker compose up
     ```  
   - Note: first boot will create DB automatically.  
   - Access at `http://localhost:3000`.  

5. **Sanity Check Section**  
   - `docker compose ps` shows healthy db + running web.  
   - Visit `/` → page loads with “Hello from roadtrip_planner!”.  
   - Restart doesn’t reinstall gems (thanks to cache volume).  

---

## Acceptance Criteria
- One command (`docker compose up`) starts everything.  
- No system dependencies beyond Docker + Compose.  
- PostgreSQL auto-prepared.  
- Live reload works from mounted volume.  

---

## Key Improvements
- Project explicitly named `roadtrip_planner`.  
- Version pinning for long-term reproducibility.  
- Minimal, Docker-only, Importmap-ready.  
- Entrypoint ensures DB is ready and app boots cleanly.  

---

## Techniques Applied
Role assignment, task decomposition, constraint pinning, structured deliverables, acceptance criteria.  

---

## Pro Tip
After generation, commit all files immediately so you can safely extend from a clean baseline.
