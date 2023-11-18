# Makefile for Backup Script

# Variables
D_DRIVE_PATH = /mnt/d
BACKUP_INTERNAL_DIR = /mnt/c/backup_internal_gateway
BACKUP_EXTERNAL_DIR = $(D_DRIVE_PATH)/backup_external_warehouse
LOG_DIR = $(BACKUP_INTERNAL_DIR)/logs
EXTERNAL_LOG_DIR = $(BACKUP_EXTERNAL_DIR)/logs
BACKUP_QUEUE_DIR = $(BACKUP_INTERNAL_DIR)/backup_queue

# Targets
all: check_environment setup_directories mount_d_drive

check_environment:
	@echo "This script will make changes to your system, including your C: and D: drives."
	@echo "It will create and/or mount the following directories:"
	@echo "  - $(D_DRIVE_PATH)"
	@echo "  - $(BACKUP_INTERNAL_DIR)"
	@echo "  - $(BACKUP_EXTERNAL_DIR)"
	@echo "  - $(LOG_DIR)"
	@echo "  - $(EXTERNAL_LOG_DIR)"
	@echo "  - $(BACKUP_QUEUE_DIR)"
	@echo "Please ensure you have sufficient permissions to make these changes."
	@read -p "Do you want to proceed with these changes? (y/N): " proceed; \
	if [ "$$proceed" != "y" ]; then \
		echo "Exiting setup."; \
		exit 1; \
	fi

setup_directories:
	@echo "Creating necessary directories..."
	@mkdir -p $(D_DRIVE_PATH)
	@mkdir -p $(BACKUP_INTERNAL_DIR)
	@mkdir -p $(BACKUP_EXTERNAL_DIR)
	@mkdir -p $(LOG_DIR)
	@mkdir -p $(EXTERNAL_LOG_DIR)
	@mkdir -p $(BACKUP_QUEUE_DIR)
	@echo "Directories created successfully."

mount_d_drive:
	@echo "Checking and mounting D: drive..."
	@if [ ! -d "$(D_DRIVE_PATH)" ]; then \
		mkdir -p $(D_DRIVE_PATH); \
	fi
	@sudo mount -t drvfs D: $(D_DRIVE_PATH)
	@echo "Mounted D: drive at $(D_DRIVE_PATH)."

# Phony targets
.PHONY: all check_environment setup_directories mount_d_drive
