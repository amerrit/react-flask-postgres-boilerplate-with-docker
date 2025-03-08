import React, { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [players, setPlayers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchPlayers = async () => {
      try {
        setLoading(true);
        const apiUrl = process.env.REACT_APP_API_URL || '/api';
        console.log('Fetching players from:', `${apiUrl}/data`);
        
        const response = await fetch(`${apiUrl}/data`);
        console.log('Response status:', response.status);
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Received data:', data);
        setPlayers(data);
        setError(null);
      } catch (err) {
        console.error('Error fetching players:', err);
        setError('Failed to load players. Please try again later.');
      } finally {
        setLoading(false);
      }
    };

    fetchPlayers();
  }, []);

  if (loading) {
    return <div className="container">Loading...</div>;
  }

  if (error) {
    return <div className="container error">{error}</div>;
  }

  return (
    <div className="container">
      <h1>Baseball Players</h1>
      {players.length === 0 ? (
        <p>No players found.</p>
      ) : (
        <ul className="players-list">
          {players.map((player, index) => (
            <li key={index} className="player-item">
              {player.name}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export default App;