import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { collection, query, where, orderBy, onSnapshot, addDoc, updateDoc, deleteDoc, doc, arrayUnion, arrayRemove, serverTimestamp } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { uploadImage } from '../../services/cloudinary';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import './CommunityHub.css';

const CommunityHub = () => {
    const { currentUser, userProfile } = useAuth();
    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [newPost, setNewPost] = useState({ content: '', imageFile: null, imagePreview: null });
    const [uploadingImage, setUploadingImage] = useState(false);
    const [selectedPost, setSelectedPost] = useState(null);
    const [commentText, setCommentText] = useState('');
    const [comments, setComments] = useState({});
    const [loadingComments, setLoadingComments] = useState({});

    // Load posts
    useEffect(() => {
        if (!userProfile?.panchayat) return;

        const q = query(
            collection(db, 'community_notes'),
            where('panchayat', '==', userProfile.panchayat),
            orderBy('createdAt', 'desc')
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const postsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setPosts(postsData);
            setLoading(false);
        }, (err) => {
            console.error('Error fetching posts:', err);
            setError('Failed to load community posts');
            setLoading(false);
        });

        return () => unsubscribe();
    }, [userProfile]);

    // Load comments when a post is selected
    useEffect(() => {
        if (!selectedPost) return;

        setLoadingComments(prev => ({ ...prev, [selectedPost]: true }));

        const commentsRef = collection(db, 'community_notes', selectedPost, 'comments');
        const q = query(commentsRef, orderBy('createdAt', 'asc'));

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const commentsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setComments(prev => ({ ...prev, [selectedPost]: commentsData }));
            setLoadingComments(prev => ({ ...prev, [selectedPost]: false }));
        }, (err) => {
            console.error('Error fetching comments:', err);
            setLoadingComments(prev => ({ ...prev, [selectedPost]: false }));
        });

        return () => unsubscribe();
    }, [selectedPost]);

    const handleImageSelect = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                setError('Image size should be less than 10MB');
                return;
            }
            setNewPost(prev => ({
                ...prev,
                imageFile: file,
                imagePreview: URL.createObjectURL(file)
            }));
        }
    };

    const handleCreatePost = async (e) => {
        e.preventDefault();
        if (!newPost.content.trim()) return;

        try {
            setUploadingImage(true);
            let imageUrl = null;

            if (newPost.imageFile) {
                imageUrl = await uploadImage(newPost.imageFile, 'community_posts');
            }

            setUploadingImage(false);

            await addDoc(collection(db, 'community_notes'), {
                content: newPost.content,
                imageUrl: imageUrl,
                authorEmail: currentUser.email,
                authorId: currentUser.uid,
                panchayat: userProfile.panchayat,
                likes: [],
                createdAt: serverTimestamp()
            });

            setNewPost({ content: '', imageFile: null, imagePreview: null });
            setShowCreateModal(false);
        } catch (err) {
            console.error('Error creating post:', err);
            setError('Failed to create post');
            setUploadingImage(false);
        }
    };

    const handleToggleLike = async (postId, likes) => {
        const postRef = doc(db, 'community_notes', postId);
        const isLiked = likes.includes(currentUser.uid);

        try {
            await updateDoc(postRef, {
                likes: isLiked ? arrayRemove(currentUser.uid) : arrayUnion(currentUser.uid)
            });
        } catch (err) {
            console.error('Error toggling like:', err);
        }
    };

    const handleDeletePost = async (postId) => {
        if (!window.confirm('Are you sure you want to delete this post?')) return;

        try {
            await deleteDoc(doc(db, 'community_notes', postId));
        } catch (err) {
            console.error('Error deleting post:', err);
            setError('Failed to delete post');
        }
    };

    const handleAddComment = async (postId) => {
        if (!commentText.trim()) return;

        try {
            const commentsRef = collection(db, 'community_notes', postId, 'comments');
            await addDoc(commentsRef, {
                text: commentText,
                authorName: currentUser.email?.split('@')[0] || 'User',
                authorId: currentUser.uid,
                createdAt: serverTimestamp()
            });
            setCommentText('');
        } catch (err) {
            console.error('Error adding comment:', err);
            setError('Failed to add comment');
        }
    };

    const handleDeleteComment = async (postId, commentId) => {
        if (!window.confirm('Delete this comment?')) return;

        try {
            await deleteDoc(doc(db, 'community_notes', postId, 'comments', commentId));
        } catch (err) {
            console.error('Error deleting comment:', err);
            setError('Failed to delete comment');
        }
    };

    if (loading) return <Loading message="Loading community posts..." />;

    return (
        <div className="community-hub-container">
            {/* Page Header */}
            <div className="ch-page-header">
                <div className="ch-header-content">
                    <h1>🤝 Community Hub</h1>
                    <p>Connect, share, and engage with your neighbors</p>
                </div>
            </div>

            {/* Welcome Card */}
            <div className="ch-welcome-card">
                <div className="ch-welcome-icon">💬</div>
                <div className="ch-welcome-content">
                    <h2>Welcome to Community Hub</h2>
                    <p>This is your space to connect with neighbors, share updates, and build stronger community bonds. Post your thoughts, photos, and updates to keep everyone informed and engaged.</p>
                </div>
            </div>

            {/* Hero Banner */}
            <div className="ch-hero-banner">
                <div className="ch-hero-content">
                    <h2>🤝 Connect with Your Community</h2>
                    <p>Share updates, engage with neighbors, and build stronger connections in your area</p>
                </div>
            </div>

            {/* Info Cards */}
            <div className="ch-info-cards">
                <div className="ch-info-card card-purple">
                    <div className="card-icon">💬</div>
                    <div className="card-content">
                        <h3>Total Posts</h3>
                        <p className="card-number">{posts.length}</p>
                        <p className="card-desc">Community discussions</p>
                    </div>
                </div>
                <div className="ch-info-card card-blue">
                    <div className="card-icon">👥</div>
                    <div className="card-content">
                        <h3>Active Members</h3>
                        <p className="card-number">{new Set(posts.map(p => p.userId)).size}</p>
                        <p className="card-desc">Contributing users</p>
                    </div>
                </div>
                <div className="ch-info-card card-pink">
                    <div className="card-icon">❤️</div>
                    <div className="card-content">
                        <h3>Total Likes</h3>
                        <p className="card-number">{posts.reduce((sum, p) => sum + (p.likes?.length || 0), 0)}</p>
                        <p className="card-desc">Community engagement</p>
                    </div>
                </div>
            </div>

            <div className="community-header">
                <div className="header-content">
                    <div className="header-icon">💬</div>
                    <div>
                        <h1>Community Posts</h1>
                        <p>Share your thoughts, photos, and updates with neighbors</p>
                    </div>
                </div>
                <button className="btn-create-post" onClick={() => setShowCreateModal(true)}>
                    <span>+</span> Create Post
                </button>
            </div>

            <ErrorMessage message={error} onClose={() => setError('')} />

            <div className="posts-container">
                {posts.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-icon">💭</div>
                        <h3>No posts yet</h3>
                        <p>Be the first to share something with your community!</p>
                    </div>
                ) : (
                    posts.map(post => (
                        <div key={post.id} className="post-card">
                            <div className="post-header">
                                <div className="post-author">
                                    <div className="author-avatar">
                                        {post.authorEmail?.charAt(0).toUpperCase()}
                                    </div>
                                    <div className="author-info">
                                        <strong>{post.authorEmail?.split('@')[0]}</strong>
                                        <span className="post-time">
                                            {post.createdAt?.toDate().toLocaleDateString()}
                                        </span>
                                    </div>
                                </div>
                                {post.authorId === currentUser.uid && (
                                    <button 
                                        className="btn-delete-post"
                                        onClick={() => handleDeletePost(post.id)}
                                    >
                                        🗑️
                                    </button>
                                )}
                            </div>

                            {post.content && (
                                <div className="post-content">
                                    <p>{post.content}</p>
                                </div>
                            )}

                            {post.imageUrl && (
                                <div className="post-image">
                                    <img src={post.imageUrl} alt="Post" />
                                </div>
                            )}

                            <div className="post-actions">
                                <button 
                                    className={`action-btn ${post.likes?.includes(currentUser.uid) ? 'liked' : ''}`}
                                    onClick={() => handleToggleLike(post.id, post.likes || [])}
                                >
                                    {post.likes?.includes(currentUser.uid) ? '❤️' : '🤍'} {post.likes?.length || 0}
                                </button>
                                <button 
                                    className="action-btn"
                                    onClick={() => setSelectedPost(selectedPost === post.id ? null : post.id)}
                                >
                                    💬 {comments[post.id]?.length || 0}
                                </button>
                            </div>

                            {/* Comments Section */}
                            {selectedPost === post.id && (
                                <div className="comments-section">
                                    <div className="comments-list">
                                        {loadingComments[post.id] ? (
                                            <div className="comments-loading">Loading comments...</div>
                                        ) : comments[post.id]?.length === 0 ? (
                                            <div className="no-comments">No comments yet. Be the first!</div>
                                        ) : (
                                            comments[post.id]?.map(comment => (
                                                <div key={comment.id} className="comment-item">
                                                    <div className="comment-header">
                                                        <strong className="comment-author">{comment.authorName}</strong>
                                                        <span className="comment-time">
                                                            {comment.createdAt?.toDate().toLocaleDateString()}
                                                        </span>
                                                        {comment.authorId === currentUser.uid && (
                                                            <button
                                                                className="btn-delete-comment"
                                                                onClick={() => handleDeleteComment(post.id, comment.id)}
                                                            >
                                                                ×
                                                            </button>
                                                        )}
                                                    </div>
                                                    <p className="comment-text">{comment.text}</p>
                                                </div>
                                            ))
                                        )}
                                    </div>

                                    <div className="comment-input-section">
                                        <input
                                            type="text"
                                            placeholder="Add a comment..."
                                            value={commentText}
                                            onChange={(e) => setCommentText(e.target.value)}
                                            onKeyPress={(e) => {
                                                if (e.key === 'Enter') {
                                                    handleAddComment(post.id);
                                                }
                                            }}
                                            className="comment-input"
                                        />
                                        <button
                                            className="btn-post-comment"
                                            onClick={() => handleAddComment(post.id)}
                                        >
                                            Post
                                        </button>
                                    </div>
                                </div>
                            )}
                        </div>
                    ))
                )}
            </div>

            {/* Create Post Modal */}
            {showCreateModal && (
                <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Create Post</h2>
                            <button className="modal-close" onClick={() => setShowCreateModal(false)}>×</button>
                        </div>
                        <form onSubmit={handleCreatePost}>
                            <textarea
                                className="post-textarea"
                                placeholder="What's on your mind?"
                                value={newPost.content}
                                onChange={(e) => setNewPost({ ...newPost, content: e.target.value })}
                                rows="5"
                                required
                            />
                            <div className="image-upload-section">
                                <input
                                    type="file"
                                    id="post-image-upload"
                                    accept="image/*"
                                    onChange={handleImageSelect}
                                    hidden
                                />
                                <label htmlFor="post-image-upload" className="image-upload-btn">
                                    📷 Add Photo
                                </label>
                                {newPost.imagePreview && (
                                    <div className="image-preview">
                                        <img src={newPost.imagePreview} alt="Preview" />
                                        <button 
                                            type="button"
                                            className="remove-image"
                                            onClick={() => setNewPost({ ...newPost, imageFile: null, imagePreview: null })}
                                        >
                                            ×
                                        </button>
                                    </div>
                                )}
                            </div>
                            <div className="modal-actions">
                                <button type="button" className="btn-cancel" onClick={() => setShowCreateModal(false)}>
                                    Cancel
                                </button>
                                <button type="submit" className="btn-submit" disabled={uploadingImage}>
                                    {uploadingImage ? 'Uploading...' : 'Post'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CommunityHub;
