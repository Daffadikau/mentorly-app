<?php
/**
 * Security Middleware for Mentorly API
 * 
 * Features:
 * - Rate limiting
 * - CSRF protection
 * - Security headers
 * - Input sanitization
 * - JWT authentication
 */

class SecurityMiddleware {
    private $redis;
    private $config;
    
    // Rate limiting configuration
    private const RATE_LIMIT_REQUESTS = 100;  // requests per window
    private const RATE_LIMIT_WINDOW = 60;     // seconds
    private const RATE_LIMIT_LOGIN = 5;       // login attempts per window
    private const RATE_LIMIT_LOGIN_WINDOW = 900; // 15 minutes
    
    public function __construct($config = []) {
        $this->config = array_merge([
            'redis_host' => '127.0.0.1',
            'redis_port' => 6379,
            'csrf_token_name' => 'csrf_token',
            'jwt_secret' => $_ENV['JWT_SECRET'] ?? 'CHANGE_THIS_SECRET',
            'jwt_algorithm' => 'HS256',
        ], $config);
        
        // Initialize Redis for rate limiting (optional, can use file-based)
        try {
            if (class_exists('Redis')) {
                $this->redis = new Redis();
                $this->redis->connect($this->config['redis_host'], $this->config['redis_port']);
            }
        } catch (Exception $e) {
            error_log("Redis connection failed: " . $e->getMessage());
        }
    }
    
    /**
     * Apply all security middleware
     */
    public function handle() {
        $this->setSecurityHeaders();
        $this->checkRateLimit();
        $this->validateCSRF();
        $this->sanitizeInputs();
    }
    
    /**
     * Set security headers
     */
    public function setSecurityHeaders() {
        // Prevent clickjacking
        header("X-Frame-Options: DENY");
        
        // Prevent MIME type sniffing
        header("X-Content-Type-Options: nosniff");
        
        // XSS Protection
        header("X-XSS-Protection: 1; mode=block");
        
        // Referrer Policy
        header("Referrer-Policy: strict-origin-when-cross-origin");
        
        // Content Security Policy
        header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none';");
        
        // Permissions Policy
        header("Permissions-Policy: geolocation=(), microphone=(), camera=()");
        
        // HSTS (uncomment when HTTPS is configured)
        // header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
        
        // Prevent caching sensitive data
        if (strpos($_SERVER['REQUEST_URI'], '/api/') !== false) {
            header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
            header("Pragma: no-cache");
        }
        
        // CORS headers (configure based on your needs)
        $allowed_origins = $_ENV['ALLOWED_ORIGINS'] ?? 'http://localhost:8080';
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        
        if (in_array($origin, explode(',', $allowed_origins))) {
            header("Access-Control-Allow-Origin: $origin");
            header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
            header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
            header("Access-Control-Allow-Credentials: true");
            header("Access-Control-Max-Age: 86400");
        }
        
        // Handle preflight
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
    
    /**
     * Rate limiting
     */
    public function checkRateLimit() {
        $identifier = $this->getClientIdentifier();
        $endpoint = $_SERVER['REQUEST_URI'];
        
        // Special rate limit for login endpoints
        if (strpos($endpoint, '/login') !== false || strpos($endpoint, '/auth') !== false) {
            $this->enforceRateLimit($identifier . ':login', self::RATE_LIMIT_LOGIN, self::RATE_LIMIT_LOGIN_WINDOW);
        } else {
            $this->enforceRateLimit($identifier, self::RATE_LIMIT_REQUESTS, self::RATE_LIMIT_WINDOW);
        }
    }
    
    /**
     * Enforce rate limit
     */
    private function enforceRateLimit($key, $maxRequests, $window) {
        if ($this->redis) {
            // Redis-based rate limiting
            $requests = $this->redis->incr($key);
            
            if ($requests === 1) {
                $this->redis->expire($key, $window);
            }
            
            if ($requests > $maxRequests) {
                $this->sendRateLimitResponse($window);
            }
            
            // Add rate limit headers
            header("X-RateLimit-Limit: $maxRequests");
            header("X-RateLimit-Remaining: " . max(0, $maxRequests - $requests));
            header("X-RateLimit-Reset: " . (time() + $this->redis->ttl($key)));
        } else {
            // File-based rate limiting (fallback)
            $this->fileBasedRateLimit($key, $maxRequests, $window);
        }
    }
    
    /**
     * File-based rate limiting (fallback)
     */
    private function fileBasedRateLimit($key, $maxRequests, $window) {
        $file = sys_get_temp_dir() . '/rate_limit_' . md5($key) . '.json';
        $now = time();
        
        $data = [];
        if (file_exists($file)) {
            $content = file_get_contents($file);
            $data = json_decode($content, true) ?: [];
        }
        
        // Remove old entries
        $data = array_filter($data, function($timestamp) use ($now, $window) {
            return ($now - $timestamp) < $window;
        });
        
        // Check limit
        if (count($data) >= $maxRequests) {
            $this->sendRateLimitResponse($window);
        }
        
        // Add new request
        $data[] = $now;
        file_put_contents($file, json_encode($data));
    }
    
    /**
     * Send rate limit exceeded response
     */
    private function sendRateLimitResponse($retryAfter) {
        http_response_code(429);
        header("Retry-After: $retryAfter");
        echo json_encode([
            'error' => 'Rate limit exceeded',
            'message' => 'Too many requests. Please try again later.',
            'retry_after' => $retryAfter
        ]);
        exit;
    }
    
    /**
     * Get client identifier for rate limiting
     */
    private function getClientIdentifier() {
        // Try to get user ID from JWT
        $userId = $this->getUserIdFromToken();
        if ($userId) {
            return 'user:' . $userId;
        }
        
        // Fall back to IP address
        return 'ip:' . $this->getClientIP();
    }
    
    /**
     * Get client IP address
     */
    private function getClientIP() {
        $ip_keys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'REMOTE_ADDR'];
        
        foreach ($ip_keys as $key) {
            if (!empty($_SERVER[$key])) {
                $ip = $_SERVER[$key];
                // Handle comma-separated IPs
                if (strpos($ip, ',') !== false) {
                    $ip = trim(explode(',', $ip)[0]);
                }
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }
        
        return '0.0.0.0';
    }
    
    /**
     * CSRF Protection
     */
    public function validateCSRF() {
        $method = $_SERVER['REQUEST_METHOD'];
        
        // Only validate for state-changing methods
        if (!in_array($method, ['POST', 'PUT', 'DELETE', 'PATCH'])) {
            return;
        }
        
        // For API endpoints using JWT, CSRF is not needed
        if ($this->hasValidJWT()) {
            return;
        }
        
        // Validate CSRF token
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? $_POST['csrf_token'] ?? '';
        
        if (!$this->verifyCSRFToken($token)) {
            http_response_code(403);
            echo json_encode(['error' => 'CSRF token validation failed']);
            exit;
        }
    }
    
    /**
     * Generate CSRF token
     */
    public static function generateCSRFToken() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        
        return $_SESSION['csrf_token'];
    }
    
    /**
     * Verify CSRF token
     */
    private function verifyCSRFToken($token) {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        $sessionToken = $_SESSION['csrf_token'] ?? '';
        
        return !empty($sessionToken) && hash_equals($sessionToken, $token);
    }
    
    /**
     * Check if request has valid JWT
     */
    private function hasValidJWT() {
        $token = $this->getBearerToken();
        return $token && $this->verifyJWT($token);
    }
    
    /**
     * Get bearer token from header
     */
    private function getBearerToken() {
        $headers = $this->getAuthorizationHeader();
        
        if (!empty($headers)) {
            if (preg_match('/Bearer\s+(.*)$/i', $headers, $matches)) {
                return $matches[1];
            }
        }
        
        return null;
    }
    
    /**
     * Get authorization header
     */
    private function getAuthorizationHeader() {
        if (isset($_SERVER['Authorization'])) {
            return trim($_SERVER['Authorization']);
        } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            return trim($_SERVER['HTTP_AUTHORIZATION']);
        } elseif (function_exists('apache_request_headers')) {
            $headers = apache_request_headers();
            if (isset($headers['Authorization'])) {
                return trim($headers['Authorization']);
            }
        }
        
        return null;
    }
    
    /**
     * Verify JWT token
     */
    private function verifyJWT($token) {
        // Simple JWT verification (consider using firebase/php-jwt library)
        try {
            $parts = explode('.', $token);
            if (count($parts) !== 3) {
                return false;
            }
            
            list($header, $payload, $signature) = $parts;
            
            // Verify signature
            $validSignature = hash_hmac(
                'sha256',
                "$header.$payload",
                $this->config['jwt_secret'],
                true
            );
            
            $validSignature = $this->base64UrlEncode($validSignature);
            
            if (!hash_equals($signature, $validSignature)) {
                return false;
            }
            
            // Check expiration
            $payloadData = json_decode($this->base64UrlDecode($payload), true);
            if (isset($payloadData['exp']) && $payloadData['exp'] < time()) {
                return false;
            }
            
            return true;
        } catch (Exception $e) {
            error_log("JWT verification failed: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Get user ID from JWT token
     */
    private function getUserIdFromToken() {
        $token = $this->getBearerToken();
        if (!$token) {
            return null;
        }
        
        try {
            $parts = explode('.', $token);
            if (count($parts) !== 3) {
                return null;
            }
            
            $payload = json_decode($this->base64UrlDecode($parts[1]), true);
            return $payload['sub'] ?? $payload['user_id'] ?? null;
        } catch (Exception $e) {
            return null;
        }
    }
    
    /**
     * Base64 URL encode
     */
    private function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    /**
     * Base64 URL decode
     */
    private function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }
    
    /**
     * Sanitize all inputs
     */
    public function sanitizeInputs() {
        $_GET = $this->sanitizeArray($_GET);
        $_POST = $this->sanitizeArray($_POST);
        $_COOKIE = $this->sanitizeArray($_COOKIE);
    }
    
    /**
     * Sanitize array recursively
     */
    private function sanitizeArray($array) {
        foreach ($array as $key => $value) {
            if (is_array($value)) {
                $array[$key] = $this->sanitizeArray($value);
            } else {
                $array[$key] = $this->sanitizeString($value);
            }
        }
        return $array;
    }
    
    /**
     * Sanitize string
     */
    private function sanitizeString($string) {
        // Remove null bytes
        $string = str_replace(chr(0), '', $string);
        
        // Trim whitespace
        $string = trim($string);
        
        // Don't strip tags here - do it in specific contexts
        return $string;
    }
    
    /**
     * Validate email
     */
    public static function validateEmail($email) {
        $email = filter_var($email, FILTER_SANITIZE_EMAIL);
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    /**
     * Hash password using Argon2id
     */
    public static function hashPassword($password) {
        if (defined('PASSWORD_ARGON2ID')) {
            return password_hash($password, PASSWORD_ARGON2ID, [
                'memory_cost' => 65536,  // 64 MB
                'time_cost' => 4,
                'threads' => 3
            ]);
        }
        
        // Fallback to bcrypt
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }
    
    /**
     * Verify password
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * Log security event
     */
    public static function logSecurityEvent($event, $details = []) {
        $log = [
            'timestamp' => date('Y-m-d H:i:s'),
            'event' => $event,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
            'details' => $details
        ];
        
        error_log('SECURITY: ' . json_encode($log));
        
        // You can also write to a dedicated security log file
        $logFile = __DIR__ . '/../logs/security.log';
        if (is_writable(dirname($logFile))) {
            file_put_contents($logFile, json_encode($log) . "\n", FILE_APPEND);
        }
    }
}

// Initialize middleware
$security = new SecurityMiddleware();
$security->handle();
