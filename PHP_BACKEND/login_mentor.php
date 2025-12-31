<?php
/**
 * Mentor Login API (PHP Backend)
 * This handles authentication for mentors who were registered before Firebase integration
 * or when Firebase Auth is unavailable
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Database connection (adjust these credentials)
$host = 'localhost';
$dbname = 'mentorly';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed'
    ]);
    exit;
}

// Get POST data
$email = isset($_POST['email']) ? trim($_POST['email']) : '';
$pass = isset($_POST['password']) ? trim($_POST['password']) : '';

if (empty($email) || empty($pass)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Email dan password harus diisi'
    ]);
    exit;
}

try {
    // Find mentor by email
    // Adjust table name and column names based on your database structure
    $stmt = $pdo->prepare("SELECT * FROM mentor WHERE email = :email LIMIT 1");
    $stmt->execute(['email' => $email]);
    
    $mentor = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$mentor) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Email tidak terdaftar'
        ]);
        exit;
    }
    
    // Verify password
    // IMPORTANT: Adjust this based on how passwords are stored in your database
    $passwordMatches = false;
    
    if (isset($mentor['password'])) {
        // Check if password is hashed
        if (password_verify($pass, $mentor['password'])) {
            // Hashed password (bcrypt/password_hash)
            $passwordMatches = true;
        } else if ($mentor['password'] === $pass) {
            // Plain text password (NOT RECOMMENDED for production)
            $passwordMatches = true;
        } else if (md5($pass) === $mentor['password']) {
            // MD5 hashed (old method)
            $passwordMatches = true;
        } else if (hash('sha256', $pass) === $mentor['password']) {
            // SHA256 hashed
            $passwordMatches = true;
        }
    }
    
    if (!$passwordMatches) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Password salah'
        ]);
        exit;
    }
    
    // Check verification status
    $isVerified = false;
    if (isset($mentor['status_verifikasi'])) {
        $isVerified = ($mentor['status_verifikasi'] === 'verified');
    } else if (isset($mentor['status'])) {
        $isVerified = ($mentor['status'] === 'verified');
    } else if (isset($mentor['verified'])) {
        $isVerified = ($mentor['verified'] == 1);
    }
    
    // Return mentor data
    echo json_encode([
        'status' => 'success',
        'message' => 'Login berhasil',
        'verified' => $isVerified,
        'mentor_data' => [
            'id' => $mentor['id'] ?? null,
            'uid' => $mentor['uid'] ?? $mentor['firebase_uid'] ?? null,
            'email' => $mentor['email'] ?? '',
            'nama_lengkap' => $mentor['nama_lengkap'] ?? '',
            'nik' => $mentor['nik'] ?? '',
            'keahlian' => $mentor['keahlian'] ?? '',
            'keahlian_utama' => $mentor['keahlian_utama'] ?? $mentor['keahlian'] ?? '',
            'keahlian_lain' => $mentor['keahlian_lain'] ?? '',
            'kelamin' => $mentor['kelamin'] ?? '',
            'linkedin' => $mentor['linkedin'] ?? '',
            'deskripsi' => $mentor['deskripsi'] ?? '',
            'status_verifikasi' => $mentor['status_verifikasi'] ?? ($isVerified ? 'verified' : 'pending'),
            'created_at' => $mentor['created_at'] ?? date('Y-m-d H:i:s'),
            // Add any other fields from your database
        ]
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Query failed: ' . $e->getMessage()
    ]);
}
?>
