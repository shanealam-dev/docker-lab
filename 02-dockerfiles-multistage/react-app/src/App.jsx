import React from 'react';

export default function App() {
  return (
    <div style={{
      fontFamily: 'system-ui, -apple-system, sans-serif',
      backgroundColor: '#0f172a',
      color: '#f8fafc',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '2rem'
    }}>
      <div style={{
        background: 'rgba(30, 41, 59, 0.7)',
        backdropFilter: 'blur(10px)',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        borderRadius: '16px',
        padding: '2.5rem',
        maxWidth: '560px',
        textAlign: 'center',
        boxShadow: '0 20px 40px rgba(0,0,0,0.4)'
      }}>
        <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🐳 ➔ ⚡</div>
        <h1 style={{ fontSize: '1.8rem', margin: '0 0 0.5rem 0', color: '#38bdf8' }}>
          Docker Hero Multi-Stage Build
        </h1>
        <p style={{ color: '#94a3b8', fontSize: '1rem', lineHeight: '1.6' }}>
          This production React application was built inside a Node container and is currently being served by an ultra-lightweight Nginx container (<strong>~25MB</strong> total)!
        </p>
        <div style={{
          marginTop: '1.5rem',
          padding: '0.8rem',
          borderRadius: '8px',
          background: '#030712',
          fontFamily: 'monospace',
          color: '#4ade80',
          fontSize: '0.9rem'
        }}>
          Stage: Runtime (Nginx Alpine) • Status: Healthy
        </div>
      </div>
    </div>
  );
}
