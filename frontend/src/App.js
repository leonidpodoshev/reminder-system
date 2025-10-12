// frontend/src/App.js
import React, { useState, useEffect } from 'react';
import { Plus, Bell, Mail, MessageSquare, Trash2, Edit2, Check, X, Calendar, Settings, CheckCircle, Clock, AlertCircle, XCircle } from 'lucide-react';

const API_BASE = process.env.REACT_APP_API_URL ? `${process.env.REACT_APP_API_URL}/api` : '/api';

// Default email settings utilities
const getDefaultEmails = () => {
  try {
    const stored = localStorage.getItem('memo-default-emails');
    console.log('getDefaultEmails - stored value:', stored);
    return stored || '';
  } catch (error) {
    console.error('Error loading default emails:', error);
    return '';
  }
};

const saveDefaultEmailsToStorage = (emails) => {
  try {
    console.log('saveDefaultEmailsToStorage - saving:', emails);
    localStorage.setItem('memo-default-emails', emails);
    console.log('saveDefaultEmailsToStorage - saved successfully');
  } catch (error) {
    console.error('Error saving default emails:', error);
  }
};

// Email validation and parsing utilities
const parseEmails = (emailString) => {
  if (!emailString) return [];
  
  // Split by comma or semicolon, then clean up
  return emailString
    .split(/[,;]/)
    .map(email => email.trim())
    .filter(email => email.length > 0);
};

const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const EmailPreview = ({ emails }) => {
  const emailList = parseEmails(emails);
  
  if (emailList.length === 0) return null;
  
  return (
    <div className="space-y-1">
      <p className="text-xs font-medium text-gray-600">
        Recipients ({emailList.length}):
      </p>
      <div className="flex flex-wrap gap-1">
        {emailList.map((email, index) => {
          const isValid = validateEmail(email);
          return (
            <span
              key={index}
              className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                isValid
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              }`}
            >
              {isValid ? '✓' : '✗'} {email}
            </span>
          );
        })}
      </div>
    </div>
  );
};

const StatusBadge = ({ status }) => {
  const getStatusConfig = (status) => {
    switch (status?.toLowerCase()) {
      case 'sent':
        return {
          icon: CheckCircle,
          text: 'Sent',
          className: 'bg-green-100 text-green-800',
          description: 'Notification delivered successfully'
        };
      case 'pending':
        return {
          icon: Clock,
          text: 'Pending',
          className: 'bg-yellow-100 text-yellow-800',
          description: 'Waiting to be sent'
        };
      case 'processing':
        return {
          icon: Clock,
          text: 'Sending',
          className: 'bg-blue-100 text-blue-800',
          description: 'Currently being sent'
        };
      case 'failed':
        return {
          icon: XCircle,
          text: 'Failed',
          className: 'bg-red-100 text-red-800',
          description: 'Failed to send notification'
        };
      default:
        return {
          icon: AlertCircle,
          text: status || 'Unknown',
          className: 'bg-gray-100 text-gray-800',
          description: 'Status unknown'
        };
    }
  };

  const config = getStatusConfig(status);
  const Icon = config.icon;

  return (
    <span
      className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${config.className}`}
      title={config.description}
    >
      <Icon className="w-3 h-3 mr-1" />
      {config.text}
    </span>
  );
};

const ReminderApp = () => {
  console.log('ReminderApp component is rendering!');
  const [reminders, setReminders] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [filter, setFilter] = useState('all');
  const [defaultEmails, setDefaultEmails] = useState(getDefaultEmails());
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    datetime: '',
    notificationType: 'email',
    email: '',
    phone: ''
  });

  useEffect(() => {
    fetchReminders();
  }, []);

  const fetchReminders = async () => {
    try {
      const response = await fetch(`${API_BASE}/reminders?user_id=default-user`);
      
      if (!response.ok) {
        console.error('Failed to fetch reminders:', response.status);
        setReminders([]); // Set empty array on error
        return;
      }
      
      const data = await response.json();
      setReminders(data || []);
    } catch (error) {
      console.error('Error fetching reminders:', error);
      setReminders([]); // Set empty array on network error
    }
  };

  const handleSubmit = async () => {
    try {
      // Validate form data
      if (!formData.title.trim()) {
        alert('Please enter a title for your reminder');
        return;
      }
      
      if (!formData.datetime) {
        alert('Please select a date and time for your reminder');
        return;
      }
      
      // Validate email addresses if email notification is selected
      if (formData.notificationType === 'email') {
        const emailList = parseEmails(formData.email);
        if (emailList.length === 0) {
          alert('Please enter at least one email address');
          return;
        }
        
        const invalidEmails = emailList.filter(email => !validateEmail(email));
        if (invalidEmails.length > 0) {
          alert(`Please fix these invalid email addresses:\n${invalidEmails.join('\n')}`);
          return;
        }
      }
      
      // Validate phone number if SMS notification is selected
      if (formData.notificationType === 'sms' && !formData.phone.trim()) {
        alert('Please enter a phone number for SMS notifications');
        return;
      }
      
      const method = editingId ? 'PUT' : 'POST';
      const url = editingId ? `${API_BASE}/reminders/${editingId}` : `${API_BASE}/reminders`;
      
      // Convert datetime-local format to RFC3339 format
      const datetimeRFC3339 = new Date(formData.datetime).toISOString();
      
      // Transform formData to match backend expectations
      const requestData = {
        title: formData.title,
        description: formData.description,
        datetime: datetimeRFC3339,
        notification_type: formData.notificationType, // Convert camelCase to snake_case
        email: formData.email, // Backend will handle parsing multiple emails
        phone: formData.phone
      };

      const response = await fetch(url, {
        method,
        headers: { 
          'Content-Type': 'application/json',
          'X-User-ID': 'default-user'
        },
        body: JSON.stringify(requestData)
      });

      if (!response.ok) {
        const errorData = await response.json();
        console.error('API Error:', errorData);
        alert(`Error: ${errorData.error || 'Failed to save reminder'}`);
        return;
      }

      // Reset form with fresh default emails after successful submission
      const currentDefaultEmails = getDefaultEmails();
      setFormData({
        title: '',
        description: '',
        datetime: '',
        notificationType: 'email',
        email: currentDefaultEmails,
        phone: ''
      });
      setEditingId(null);
      setShowModal(false);
      fetchReminders();
    } catch (error) {
      console.error('Error saving reminder:', error);
      alert('Network error: Failed to save reminder');
    }
  };

  const deleteReminder = async (id) => {
    try {
      await fetch(`${API_BASE}/reminders/${id}?user_id=default-user`, { 
        method: 'DELETE' 
      });
      setReminders(reminders.filter(r => r.id !== id));
    } catch (error) {
      console.error('Error deleting reminder:', error);
    }
  };

  const editReminder = (reminder) => {
    // Convert ISO datetime back to datetime-local format for the input
    const localDatetime = reminder.datetime ? new Date(reminder.datetime).toISOString().slice(0, 16) : '';
    
    setFormData({
      title: reminder.title,
      description: reminder.description,
      datetime: localDatetime,
      notificationType: reminder.notification_type || reminder.notificationType,
      email: reminder.email || '',
      phone: reminder.phone || ''
    });
    setEditingId(reminder.id);
    setShowModal(true);
  };

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      datetime: '',
      notificationType: 'email',
      email: '',
      phone: ''
    });
    setEditingId(null);
    setShowModal(false);
  };

  const saveDefaultEmailsHandler = (emails) => {
    console.log('saveDefaultEmailsHandler called with:', emails);
    alert('Save button clicked! Emails: ' + emails); // Visible debug
    setDefaultEmails(emails); // Update state
    saveDefaultEmailsToStorage(emails); // Save to localStorage using the utility function
    setShowSettings(false);
  };

  const saveDefaultEmailsHandler = (emails) => {
    setDefaultEmails(emails); // Update state
    saveDefaultEmailsToStorage(emails); // Save to localStorage using the utility function
    setShowSettings(false);
  };

  const filteredReminders = reminders.filter(r => {
    if (filter === 'all') return true;
    const notificationType = r.notification_type || r.notificationType;
    if (filter === 'email') return notificationType === 'email';
    if (filter === 'sms') return notificationType === 'sms';
    return true;
  });

  const formatDateTime = (datetime) => {
    const date = new Date(datetime);
    return date.toLocaleString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric',
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <header className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Bell className="w-8 h-8 text-indigo-600" />
              <h1 className="text-3xl font-bold text-gray-900">Reminder System</h1>
            </div>
            <div className="flex items-center space-x-3">
              <button
                onClick={() => setShowSettings(true)}
                className="flex items-center space-x-2 bg-gray-100 text-gray-700 px-3 py-2 rounded-lg hover:bg-gray-200 transition-colors"
                title="Settings"
              >
                <Settings className="w-5 h-5" />
              </button>
              <button
                onClick={() => {
                  // Reset form with fresh default emails when opening modal
                  const currentDefaultEmails = getDefaultEmails();
                  console.log('Opening modal - default emails from localStorage:', currentDefaultEmails);
                  alert('New Reminder clicked! Default emails: "' + currentDefaultEmails + '"'); // Visible debug
                  setFormData({
                    title: '',
                    description: '',
                    datetime: '',
                    notificationType: 'email',
                    email: currentDefaultEmails,
                    phone: ''
                  });
                  setEditingId(null);
                  setShowModal(true);
                }}
                className="flex items-center space-x-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
              >
                <Plus className="w-5 h-5" />
                <span>New Reminder</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <div className="mb-6 flex space-x-4">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'all' 
                ? 'bg-indigo-600 text-white' 
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
          >
            All Reminders
          </button>
          <button
            onClick={() => setFilter('email')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'email' 
                ? 'bg-indigo-600 text-white' 
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
          >
            <Mail className="w-4 h-4" />
            <span>Email</span>
          </button>
          <button
            onClick={() => setFilter('sms')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'sms' 
                ? 'bg-indigo-600 text-white' 
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
          >
            <MessageSquare className="w-4 h-4" />
            <span>SMS</span>
          </button>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredReminders.map(reminder => (
            <div
              key={reminder.id}
              className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">{reminder.title}</h3>
                  <StatusBadge status={reminder.status} />
                </div>
                <div className="flex items-center space-x-2">
                  {(reminder.notification_type || reminder.notificationType) === 'email' ? (
                    <Mail className="w-5 h-5 text-blue-500" />
                  ) : (
                    <MessageSquare className="w-5 h-5 text-green-500" />
                  )}
                </div>
              </div>
              
              <p className="text-gray-600 mb-4">{reminder.description}</p>
              
              <div className="flex items-center text-sm text-gray-500 mb-2">
                <Calendar className="w-4 h-4 mr-2" />
                <span>{formatDateTime(reminder.datetime)}</span>
              </div>

              {reminder.email && (
                <div className="text-sm text-gray-500 mb-4">
                  <div className="font-medium mb-1">Recipients:</div>
                  <div className="flex flex-wrap gap-1">
                    {parseEmails(reminder.email).map((email, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800"
                      >
                        {email}
                      </span>
                    ))}
                  </div>
                </div>
              )}
              
              {reminder.phone && (
                <div className="text-sm text-gray-500 mb-4">
                  To: {reminder.phone}
                </div>
              )}

              <div className="flex space-x-2 pt-4 border-t">
                <button
                  onClick={() => editReminder(reminder)}
                  className="flex-1 flex items-center justify-center space-x-2 bg-blue-50 text-blue-600 px-3 py-2 rounded hover:bg-blue-100 transition-colors"
                >
                  <Edit2 className="w-4 h-4" />
                  <span>Edit</span>
                </button>
                <button
                  onClick={() => deleteReminder(reminder.id)}
                  className="flex-1 flex items-center justify-center space-x-2 bg-red-50 text-red-600 px-3 py-2 rounded hover:bg-red-100 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Delete</span>
                </button>
              </div>
            </div>
          ))}
        </div>

        {filteredReminders.length === 0 && (
          <div className="text-center py-12">
            <Bell className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-medium text-gray-600 mb-2">No reminders yet</h3>
            <p className="text-gray-500">Create your first reminder to get started!</p>
          </div>
        )}
      </main>

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold text-gray-900">
                {editingId ? 'Edit Reminder' : 'New Reminder'}
              </h2>
              <button
                onClick={resetForm}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Title
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  placeholder="Meeting, Appointment, etc."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  rows="3"
                  placeholder="Additional details..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Date and Time
                </label>
                <input
                  type="datetime-local"
                  value={formData.datetime}
                  onChange={(e) => setFormData({ ...formData, datetime: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Notification Type
                </label>
                <select
                  value={formData.notificationType}
                  onChange={(e) => setFormData({ ...formData, notificationType: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                >
                  <option value="email">Email</option>
                  <option value="sms">SMS</option>
                </select>
              </div>

              {formData.notificationType === 'email' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Email Addresses
                  </label>
                  <textarea
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    rows="3"
                    placeholder="user1@example.com, user2@example.com&#10;Or separate with semicolons: user3@example.com; user4@example.com"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    💡 Separate multiple email addresses with commas (,) or semicolons (;)
                  </p>
                  {formData.email && (
                    <div className="mt-2">
                      <EmailPreview emails={formData.email} />
                    </div>
                  )}
                </div>
              )}

              {formData.notificationType === 'sms' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Phone Number
                  </label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                    placeholder="+1234567890"
                  />
                </div>
              )}

              <div className="flex space-x-3 pt-4">
                <button
                  onClick={resetForm}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSubmit}
                  className="flex-1 flex items-center justify-center space-x-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  <Check className="w-5 h-5" />
                  <span>{editingId ? 'Update' : 'Create'}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showSettings && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold text-gray-900">Settings</h2>
              <button
                onClick={() => setShowSettings(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Default Email Addresses
                </label>
                <textarea
                  value={defaultEmails}
                  onChange={(e) => setDefaultEmails(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  rows="3"
                  placeholder="user1@example.com, user2@example.com&#10;Or separate with semicolons: user3@example.com; user4@example.com"
                />
                <p className="text-xs text-gray-500 mt-1">
                  💡 These email addresses will be automatically filled when creating new reminders. You can still edit them for each reminder.
                </p>
                {defaultEmails && (
                  <div className="mt-2">
                    <EmailPreview emails={defaultEmails} />
                  </div>
                )}
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  onClick={() => setShowSettings(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => saveDefaultEmailsHandler(defaultEmails)}
                  className="flex-1 flex items-center justify-center space-x-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  <Check className="w-5 h-5" />
                  <span>Save</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReminderApp;