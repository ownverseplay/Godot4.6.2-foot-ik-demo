# Godot 4.6.2 Foot IK Demo (Leg & Foot Alignment on Slopes & Stairs)

An open-source starter package and implementation demo for a robust 3D 2-Bone Inverse Kinematics (Foot IK) system in **Godot 4.6.2**. This project demonstrates how to make a character's feet dynamically adapt to uneven terrains, such as hills, slopes, and stairs, using `TwoBoneIK3D` and `RayCast3D` nodes.

---

## 📺 Watch the Full Tutorial

Struggling with character legs clipping through the ground or broken running animations? Check out the complete step-by-step video guide on YouTube! 

[![Watch the tutorial](https://img.youtube.com/vi/ctY-D8jyF5Y/maxresdefault.jpg)](https://www.youtube.com/watch?v=ctY-D8jyF5Y)

> 💡 **[Click here to watch the tutorial on YouTube!](https://www.youtube.com/watch?v=ctY-D8jyF5Y)**

---

## ✨ Features Covered
- **Scene & Node Setup:** Clean hierarchy involving `TwoBoneIK3D`, `RayCast3D`, Target, and Pole nodes.
- **Perfect Alignment Trick:** Workflow tip on duplicating reference meshes to align the original rest pose in one take.
- **Animation Correction:** Understanding why the running animation breaks without GDScript, and how to fix it dynamically.
- **Underlying Mechanism:** Step-by-step breakdown using `@export` variables instead of skipping straight to `@onready` shortcuts.

*Note: This repository serves as the starter package and Part 1 of the implementation (Leg Alignment). Advanced foot rotation calculation will be covered in Part 2!*

---

## 🚀 Getting Started

### Prerequisites
- **Godot Engine 4.6.2** (or higher recommended)

### Installation
1. Clone this repository to your local machine:
   ```bash
   git clone [https://github.com/ownverseplay/Godot4.6.2-foot-ik-demo.git](https://github.com/ownverseplay/Godot4.6.2-foot-ik-demo.git)
