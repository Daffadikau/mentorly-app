<?php
/**
 * Check Mentor Status API
 * This file checks if a mentor is verified in the PHP database
 * and returns their data for syncing with Firebase
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
$uid = isset($_POST['uid']) ? trim($_POST['uid']) : '';
$email = isset($_POST['email']) ? trim($_POST['email']) : '';

if (empty($uid) && empty($email)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'UID or email required'
    ]);
    exit;
}

try {
    // Check mentor in database
    // Adjust table name and column names based on your actual database structure
    if (!empty($uid)) {
        $stmt = $pdo->prepare("SELECT * FROM mentor WHERE uid = :uid OR firebase_uid = :uid LIMIT 1");
        $stmt->execute(['uid' => $uid]);
    } else {
        $stmt = $pdo->prepare("SELECT * FROM mentor WHERE email = :email LIMIT 1");
        $stmt->execute(['email' => $email]);
    }
    
    $mentor = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($mentor) {
        // Check if mentor is verified
        // Adjust the column name based on your database
        $isVerified = ($mentor['status_verifikasi'] === 'verified' || 
                       $mentor['status'] === 'verified' ||
                       $mentor['verified'] == 1);
        
        echo json_encode([
            'status' => 'success',
            'verified' => $isVerified,
            'mentor_data' => [
                'uid' => $mentor['uid'] ?? $mentor['firebase_uid'] ?? $uid,
                'email' => $mentor['email'] ?? '',
                'nama_lengkap' => $mentor['nama_lengkap'] ?? '',
                'nik' => $mentor['nik'] ?? '',
                'keahlian' => $mentor['keahlian'] ?? '',
                'keahlian_lain' => $mentor['keahlian_lain'] ?? '',
                'kelamin' => $mentor['kelamin'] ?? '',
                'linkedin' => $mentor['linkedin'] ?? '',
                'status_verifikasi' => $mentor['status_verifikasi'] ?? 'pending',
                'created_at' => $mentor['created_at'] ?? date('Y-m-d H:i:s'),
            ]
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'verified' => false,
            'message' => 'Mentor not found'
        ]);
    }
    
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Query failed: ' . $e->getMessage()
    ]);
}
?>
