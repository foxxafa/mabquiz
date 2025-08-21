import redis
import json
import os
from typing import Optional, Dict, Any
from datetime import timedelta

class RedisManager:
    def __init__(self):
        # Railway Redis connection
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.redis_client = redis.from_url(redis_url, decode_responses=True)
        
    async def set_session(self, user_id: str, session_data: Dict[str, Any], expire_hours: int = 24 * 7):
        """Set user session data"""
        session_key = f"session:{user_id}"
        
        try:
            self.redis_client.setex(
                session_key,
                timedelta(hours=expire_hours),
                json.dumps(session_data)
            )
            return True
        except Exception as e:
            print(f"Redis session error: {e}")
            return False
    
    async def get_session(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user session data"""
        session_key = f"session:{user_id}"
        
        try:
            session_data = self.redis_client.get(session_key)
            if session_data:
                return json.loads(session_data)
            return None
        except Exception as e:
            print(f"Redis get session error: {e}")
            return None
    
    async def delete_session(self, user_id: str) -> bool:
        """Delete user session"""
        session_key = f"session:{user_id}"
        
        try:
            return self.redis_client.delete(session_key) > 0
        except Exception as e:
            print(f"Redis delete session error: {e}")
            return False
    
    async def cache_mab_data(self, user_id: str, topic: str, mab_data: Dict[str, Any], expire_hours: int = 24):
        """Cache MAB topic data"""
        mab_key = f"mab:{user_id}:{topic}"
        
        try:
            self.redis_client.setex(
                mab_key,
                timedelta(hours=expire_hours),
                json.dumps(mab_data)
            )
            return True
        except Exception as e:
            print(f"Redis MAB cache error: {e}")
            return False
    
    async def get_mab_data(self, user_id: str, topic: str) -> Optional[Dict[str, Any]]:
        """Get cached MAB data"""
        mab_key = f"mab:{user_id}:{topic}"
        
        try:
            mab_data = self.redis_client.get(mab_key)
            if mab_data:
                return json.loads(mab_data)
            return None
        except Exception as e:
            print(f"Redis get MAB error: {e}")
            return None
    
    async def cache_user_stats(self, user_id: str, stats: Dict[str, Any], expire_hours: int = 1):
        """Cache user performance statistics"""
        stats_key = f"stats:{user_id}"
        
        try:
            self.redis_client.setex(
                stats_key,
                timedelta(hours=expire_hours),
                json.dumps(stats)
            )
            return True
        except Exception as e:
            print(f"Redis stats cache error: {e}")
            return False
    
    async def get_user_stats(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get cached user statistics"""
        stats_key = f"stats:{user_id}"
        
        try:
            stats_data = self.redis_client.get(stats_key)
            if stats_data:
                return json.loads(stats_data)
            return None
        except Exception as e:
            print(f"Redis get stats error: {e}")
            return None
    
    def health_check(self) -> bool:
        """Check Redis connection"""
        try:
            self.redis_client.ping()
            return True
        except Exception:
            return False

# Global Redis instance
redis_manager = RedisManager()