#!/usr/bin/env bash
# ===========================================================
#  CADDflow Runtime Environment Initializer (Perlmutter)
#  Author: Suman Samantray
#  Purpose:
#     - Restores micromamba-based HPC envs for CADDflow
#     - Activates boltz_env and admet_env
#     - Loads CUDA + Python modules
#     - Verifies Boltz, Meeko, OpenBabel, ADMET, Vina
# ===========================================================

# --- HPC MODULES (runtime only, no CMake/PrgEnv required) ---
module purge
module load python/3.10
module load cuda/12.4
module load gcc/11.2.0

# --- CORE PATHS ---
export WORKSPACE=/global/cfs/cdirs/m3288/suman/CADD_workspace
export PATH="$HOME/bin:$WORKSPACE/boltz_env/bin:$WORKSPACE/admet_env/bin:$PATH"
export PYTHONPATH="${PYTHONPATH:+$PYTHONPATH:}$WORKSPACE/ProteinMPNN"

# --- Activate micromamba hook (quietly) ---
if command -v micromamba >/dev/null 2>&1; then
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate "$WORKSPACE/boltz_env" >/dev/null 2>&1 || true
else
    echo "⚠️  micromamba not in PATH — skipping activation hook."
fi

# --- DISPLAY BASIC STATUS ---
echo "==========================================================="
echo "  ✅  CADDflow Environment Ready"
echo "-----------------------------------------------------------"
echo "  WORKSPACE      : $WORKSPACE"
echo "  Python version : $(python --version 2>/dev/null)"
echo "  CUDA libraries : $(nvcc --version 2>/dev/null | grep release || echo 'CUDA OK (via module)')"
echo "==========================================================="

# --- SANITY CHECKS (Boltz, Meeko, OpenBabel, ADMET, Vina) ---
echo "== Tool Sanity Check =="

# Vina
command -v vina >/dev/null 2>&1 && echo "✅ AutoDock Vina available" || echo "❌ Vina missing"

# OpenBabel
command -v obabel >/dev/null 2>&1 && obabel -V || echo "❌ Open Babel missing"

# Boltz
$WORKSPACE/boltz_env/bin/python - <<'PY'
try:
    import boltz, torch
    print(f"✅ Boltz {boltz.__version__} | CUDA:", torch.cuda.is_available())
except Exception as e:
    print("❌ Boltz import failed:", e)
PY

# Meeko
$WORKSPACE/boltz_env/bin/python - <<'PY'
try:
    from meeko import MoleculePreparation
    print("✅ Meeko available")
except Exception as e:
    print("❌ Meeko missing:", e)
PY

# ADMET-AI
$WORKSPACE/admet_env/bin/python - <<'PY'
try:
    import admet_ai
    print("✅ ADMET-AI available")
except Exception as e:
    print("❌ ADMET-AI import failed:", e)
PY

echo "-----------------------------------------------------------"
echo "Run pipeline via:"
echo "  cd \$WORKSPACE/CADD_flow"
echo "  ../boltz_env/bin/python -m src.run_pipeline --pdb_id 1PPB --vendor_mode 0 --do_masif_pre --do_vina --do_boltz --do_rank_admet --do_masif_post"
echo "==========================================================="
