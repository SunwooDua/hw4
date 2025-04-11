import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: MyHomePage(title: 'Firebase Auth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RegisterEmailSection(auth: _auth),
            EmailPasswordForm(auth: _auth),
          ],
        ),
      ),
    );
  }
}

class RegisterEmailSection extends StatefulWidget {
  RegisterEmailSection({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;
  @override
  _RegisterEmailSectionState createState() => _RegisterEmailSectionState();
}

class _RegisterEmailSectionState extends State<RegisterEmailSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _success = false;
  bool _initialState = true;
  String? _userEmail;

  void _register() async {
    String displayName = '';

    try {
      UserCredential userCredential = await widget.auth
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateProfile(
          displayName:
              "${_firstNameController.text} ${_lastNameController.text}",
        );
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'role': 'user', // default is user
          'registeredDate': Timestamp.now(), // when user registered
        });
      }

      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@') || !value.contains('.com')) {
                return 'Please enter correct email format"';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length <= 6) {
                return 'Password must be longer than 6 characters';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _register();
                }
              },
              child: Text('Submit'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              _initialState
                  ? 'Please Register'
                  : _success
                  ? 'Successfully registered $_userEmail'
                  : 'Registration failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class EmailPasswordForm extends StatefulWidget {
  EmailPasswordForm({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;
  @override
  _EmailPasswordFormState createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success = false;
  bool _initialState = true;
  String _userEmail = '';
  void _signInWithEmailAndPassword() async {
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
      // if successful login, navigate to profile screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  MessageBoardList(userEmail: _userEmail, auth: widget.auth),
        ),
      );
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text('Test sign in with email and password'),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _signInWithEmailAndPassword();
                }
              },
              child: Text('Submit'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _initialState
                  ? 'Please sign in'
                  : _success
                  ? 'Successfully signed in $_userEmail'
                  : 'Sign in failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatefulWidget {
  final String userEmail;
  final FirebaseAuth auth;

  ProfileScreen({required this.userEmail, required this.auth});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _newPasswordController =
      TextEditingController(); // change password
  // change information
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  String? _registrationDate;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final user = widget.auth.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null) {
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _roleController.text = data['role'] ?? '';
        Timestamp? timestamp = data['registeredAt'];
        if (timestamp != null) {
          _registrationDate = timestamp.toDate().toString();
        }
        setState(() {});
      }
    }
  }

  // Logout function
  void _signOut(BuildContext context) async {
    await widget.auth.signOut();
    // Navigate back to the login screen (MyHomePage)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: 'Firebase Auth Demo'),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Signed out successfully')));
  }

  void _changePassword(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Get current user
        User? user = widget.auth.currentUser;

        // Update the password
        await user?.updatePassword(_newPasswordController.text);
        await user?.reload(); // Reload to get the updated user data
        user = widget.auth.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error changing password: $e')));
      }
    }
  }

  void _changeProfile(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Get current user
      User? user = widget.auth.currentUser;

      // Update the profile
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'firstName': _firstNameController.text,
              'lastName': _lastNameController.text,
              'role': _roleController.text,
            });

        await user.updateDisplayName(
          "${_firstNameController.text} ${_lastNameController.text}",
        );
        await user.reload(); // Reload to get the updated user data
        user = widget.auth.currentUser;

        _loadProfile();

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile changed successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body:
          user == null
              ? Center(
                child: Text("No User is Signed in"),
              ) // if no user is signed in
              : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text("email : ${user.email}"),
                    Text("Name : ${user.displayName}"),
                    Text("Role : ${_roleController.text}"),
                    Text("Info : ${user.metadata}"),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(labelText: "First Name"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter a First Name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: 'Last Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter a Last Name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _roleController,
                      decoration: InputDecoration(labelText: 'Role'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter a Role';
                        }
                        return null;
                      },
                    ),
                    Text('Registerd at : $_registrationDate'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _changeProfile(context),
                      child: Text('Save Changed Profile Info'),
                    ),
                    Divider(),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _changePassword(context),
                      child: Text('Change Password'),
                    ),
                  ],
                ),
              ),
    );
  }
}

class MessageBoard extends StatefulWidget {
  // messageboard where you can send and see messages
  final FirebaseAuth auth;
  final String userEmail;
  final String boardName;

  MessageBoard({
    required this.auth,
    required this.userEmail,
    required this.boardName,
  });

  @override
  State<MessageBoard> createState() => _MessageBoardState();
}

class _MessageBoardState extends State<MessageBoard> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // need datetime, message, name
  Future<void> _sendMessages() async {
    if (_messageController.text.trim().isEmpty)
      return; // when empty just return

    await _firestore
        .collection('messageBoard')
        .doc(widget.boardName)
        .collection('messages')
        .add({
          'text': _messageController.text.trim(), // messages
          'time': FieldValue.serverTimestamp(), // datetime
          'name': widget.userEmail,
        });
    _messageController.clear(); // clear after done
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: // update when messages in firestore changes
                  FirebaseFirestore.instance
                      .collection('messageBoard')
                      .doc(widget.boardName)
                      .collection('messages')
                      .orderBy('time', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  // when there is no data, show circularprogressindicator
                  return Center(child: CircularProgressIndicator());
                }

                final messages =
                    snapshot.data!.docs; // if data, show all the messages

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    var data = message.data() as Map<String, dynamic>;
                    var time = '';
                    if (data['time'] != null) {
                      var formattedTime = (data['time'] as Timestamp).toDate();
                      time = '${formattedTime.hour}:${formattedTime.minute}';
                    }
                    return ListTile(
                      title: Text(data['text'] ?? ''), // message
                      subtitle: Text(data['name'] ?? ''), // user name
                      trailing: Text(time),
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Enter Message'),
                  ),
                ),
                IconButton(onPressed: _sendMessages, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBoardList extends StatelessWidget {
  final FirebaseAuth auth;
  final String userEmail;

  const MessageBoardList({
    super.key,
    required this.auth,
    required this.userEmail,
  });
  // since hard code is allowed
  final List<Map<String, dynamic>> boards = const [
    {'name': 'Discussion', 'icon': Icons.chat_bubble},
    {'name': 'Study', 'icon': Icons.school},
    {'name': 'Game', 'icon': Icons.videogame_asset},
    {'name': 'Meme', 'icon': Icons.image},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Boards'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Pages'),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ProfileScreen(userEmail: userEmail, auth: auth),
                  ),
                );
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.settings),
            //   title: Text("Setting"),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder:
            //             (context) =>
            //                 ProfileScreen(userEmail: userEmail, auth: auth),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: boards.length, // hardcoded boards
        itemBuilder: (context, index) {
          final board = boards[index];
          return ListTile(
            leading: Icon(board['icon'], color: Colors.blue),
            title: Text(board['name']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MessageBoard(
                        auth: auth,
                        userEmail: userEmail,
                        boardName: board['name'],
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
