"""
FastAPI Application Entry Point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="KYC Agentic System API",
    description="AI-powered Know Your Customer due diligence system",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root() -> dict[str, str]:
    """Health check endpoint"""
    return {"status": "healthy", "service": "kyc-backend"}


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint"""
    return {"status": "ok"}
