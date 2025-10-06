const { Appointment, User, Therapist } = require('../models');
const nodemailer = require('nodemailer');
require('dotenv').config();

class AppointmentController {
  // Get all appointments (for admin)
  static async getAllAppointments(req, res, next) {
    try {
      const appointments = await Appointment.find()
        .populate('userId', 'username email')
        .populate('therapistId', 'name email phone specialty')
        .sort({ createdAt: -1 });

      // Transform the data for admin view
      const transformedAppointments = appointments.map(appointment => ({
        _id: appointment._id,
        userEmail: appointment.userId?.email || 'Unknown User',
        therapistEmail: appointment.therapistId?.email || 'Unknown Therapist',
        type: appointment.type || 'Unknown',
        status: appointment.status,
        date: appointment.appointmentDate ? new Date(appointment.appointmentDate).toLocaleDateString() : 'N/A',
        time: appointment.appointmentDate ? new Date(appointment.appointmentDate).toLocaleTimeString() : 'N/A',
        duration: appointment.duration,
        fee: appointment.fee,
        meetingLink: appointment.meetingLink,
        notes: appointment.notes,
        createdAt: appointment.createdAt
      }));

      res.json(transformedAppointments);
    } catch (error) {
      next(error);
    }
  }

  // Get all appointments for a user
  static async getUserAppointments(req, res, next) {
    try {
      const userId = req.params.userId;

      const appointments = await Appointment.find({ userId })
        .populate('therapistId', 'name email phone specialty location')
        .sort({ appointmentDate: -1 });

      // Transform the data to include therapist info in a more accessible format
      const transformedAppointments = appointments.map(appointment => ({
        _id: appointment._id,
        userId: appointment.userId,
        therapistId: appointment.therapistId._id,
        therapistName: appointment.therapistId.name,
        therapistEmail: appointment.therapistId.email,
        therapistPhone: appointment.therapistId.phone,
        therapistSpecialty: appointment.therapistId.specialty,
        therapistLocation: appointment.therapistId.location,
        appointmentDate: appointment.appointmentDate,
        duration: appointment.duration,
        status: appointment.status,
        notes: appointment.notes,
        meetingLink: appointment.meetingLink,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt
      }));

      res.json(transformedAppointments);
    } catch (error) {
      next(error);
    }
  }

  // Get all appointments for a therapist
  static async getTherapistAppointments(req, res, next) {
    try {
      const therapistId = req.params.therapistId;

      const appointments = await Appointment.find({ therapistId })
        .populate('userId', 'username email')
        .sort({ appointmentDate: 1 });

      // Transform the data for therapist dashboard
      const transformedAppointments = appointments.map(appointment => ({
        id: appointment._id,
        patientName: appointment.userId?.username || 'Unknown Patient',
        patientEmail: appointment.userId?.email || '',
        time: appointment.appointmentDate ? new Date(appointment.appointmentDate).toLocaleTimeString() : '',
        duration: appointment.duration || 60,
        type: appointment.type || 'consultation',
        meetingLink: appointment.meetingLink || null,
        notes: appointment.notes || '',
        status: appointment.status || 'scheduled',
        patientPhone: appointment.patientPhone || '',
        appointmentDate: appointment.appointmentDate,
        fee: appointment.fee
      }));

      res.json(transformedAppointments);
    } catch (error) {
      next(error);
    }
  }

  // Get single appointment details
  static async getAppointmentById(req, res, next) {
    try {
      const appointmentId = req.params.appointmentId;
      
      const appointment = await Appointment.findById(appointmentId)
        .populate('userId', 'username email')
        .populate('therapistId', 'name specialty');
      
      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }
      
      res.json(appointment);
    } catch (error) {
      next(error);
    }
  }

  // Book a new appointment
  static async bookAppointment(req, res, next) {
    try {
      const { userId, therapistId, appointmentDate, duration, notes, type = 'online' } = req.body;
      
      // Check if user exists
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      
      // Check if therapist exists
      const therapist = await Therapist.findById(therapistId);
      if (!therapist) {
        return res.status(404).json({ message: 'Therapist not found' });
      }
      
      // Check if the appointment time is available
      const appointmentDateTime = new Date(appointmentDate);
      
      // Check if date is in the past
      if (appointmentDateTime < new Date()) {
        return res.status(400).json({ message: 'Cannot book appointments in the past' });
      }
      
      // Calculate end time for the requested appointment
      const endTime = new Date(appointmentDateTime);
      endTime.setMinutes(endTime.getMinutes() + duration);
      
      // Check for any overlapping appointments for this therapist
      const conflictingAppointment = await Appointment.findOne({
        therapistId,
        status: { $nin: ['cancelled', 'completed'] },
        $or: [
          // Case 1: Existing appointment starts before new appointment but ends after new appointment starts
          {
            appointmentDate: { $lt: appointmentDateTime },
            $expr: {
              $gt: [
                { $add: ['$appointmentDate', { $multiply: ['$duration', 60000] }] },
                appointmentDateTime
              ]
            }
          },
          // Case 2: Existing appointment starts during new appointment time
          {
            appointmentDate: {
              $gte: appointmentDateTime,
              $lt: endTime
            }
          },
          // Case 3: New appointment starts exactly when existing appointment starts
          {
            appointmentDate: appointmentDateTime
          }
        ]
      });
      
      if (conflictingAppointment) {
        const conflictStart = new Date(conflictingAppointment.appointmentDate);
        const conflictEnd = new Date(conflictStart.getTime() + conflictingAppointment.duration * 60000);
        return res.status(409).json({
          message: 'This time slot is not available. There is already an appointment scheduled.',
          conflictingAppointment: {
            start: conflictStart.toISOString(),
            end: conflictEnd.toISOString(),
            duration: conflictingAppointment.duration
          }
        });
      }
      
      // Generate a meeting link only for online appointments
      let meetingLink = null;
      if (type === 'online' || type === 'instant') {
        const meetingId = `appointment-${userId}-${therapistId}-${Date.now()}`;
        meetingLink = await AppointmentController._generateMeetingLink(meetingId);
      }

      // Create the appointment
      const newAppointment = new Appointment({
        userId,
        therapistId,
        appointmentDate: appointmentDateTime,
        duration,
        notes,
        type,
        meetingLink,
        status: 'scheduled'
      });
      
      await newAppointment.save();
      
      // Send confirmation emails
      await AppointmentController._sendConfirmationEmails(user, therapist, newAppointment);
      
      res.status(201).json(newAppointment);
    } catch (error) {
      next(error);
    }
  }

  // Update appointment details
  static async updateAppointment(req, res, next) {
    try {
      const appointmentId = req.params.appointmentId;
      const { appointmentDate, duration, notes, status } = req.body;
      
      const appointment = await Appointment.findById(appointmentId);
      
      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }
      
      // If changing the date or duration, check for conflicts
      if ((appointmentDate && appointmentDate !== appointment.appointmentDate.toISOString()) || 
          (duration && duration !== appointment.duration)) {
        
        const newAppointmentDate = appointmentDate ? new Date(appointmentDate) : appointment.appointmentDate;
        const newDuration = duration || appointment.duration;
        
        // Check if date is in the past
        if (newAppointmentDate < new Date()) {
          return res.status(400).json({ message: 'Cannot reschedule to a past date' });
        }
        
        // Calculate end time for the requested appointment
        const endTime = new Date(newAppointmentDate);
        endTime.setMinutes(endTime.getMinutes() + newDuration);
        
        // Check for any overlapping appointments
        // const conflictingAppointment = await Appointment.findOne({
        //   _id: { $ne: appointmentId },
        //   therapistId: appointment.therapistId,
        //   status: { $ne: 'cancelled' },
        //   $or: [
        //     // New appointment starts during an existing appointment
        //     {
        //       appointmentDate: { $lte: newAppointmentDate },
        //       $expr: {
        //         $gt: [
        //           { $add: ['$appointmentDate', { $multiply: ['$duration', 60000] }] },
        //           newAppointmentDate.getTime()
        //         ]
        //       }
        //     },
        //     // New appointment ends during an existing appointment
        //     {
        //       appointmentDate: { $lt: endTime },
        //       appointmentDate: { $gt: newAppointmentDate }
        //     }
        //   ]
        // });
        
        // if (conflictingAppointment) {
        //   return res.status(409).json({ 
        //     message: 'This time slot is not available',
        //     conflictingAppointment
        //   });
        // }
      }
      
      // Update appointment fields
      if (appointmentDate) appointment.appointmentDate = new Date(appointmentDate);
      if (duration) appointment.duration = duration;
      if (notes) appointment.notes = notes;
      if (status) appointment.status = status;
      
      appointment.updatedAt = new Date();
      
      await appointment.save();
      
      // If rescheduled, send notifications
      if (status === 'rescheduled' || appointmentDate) {
        const user = await User.findById(appointment.userId);
        const therapist = await Therapist.findById(appointment.therapistId);
        await AppointmentController._sendRescheduledEmails(user, therapist, appointment);
      }
      
      res.json(appointment);
    } catch (error) {
      next(error);
    }
  }

  // Cancel an appointment
  static async cancelAppointment(req, res, next) {
    try {
      const appointmentId = req.params.appointmentId;
      
      const appointment = await Appointment.findById(appointmentId);
      
      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }
      
      // Check if appointment is already cancelled
      if (appointment.status === 'cancelled') {
        return res.status(400).json({ message: 'Appointment is already cancelled' });
      }
      
      // Check if appointment is in the past
      if (appointment.appointmentDate < new Date()) {
        return res.status(400).json({ message: 'Cannot cancel past appointments' });
      }
      
      appointment.status = 'cancelled';
      appointment.updatedAt = new Date();
      
      await appointment.save();
      
      // Send cancellation emails
      const user = await User.findById(appointment.userId);
      const therapist = await Therapist.findById(appointment.therapistId);
      await AppointmentController._sendCancellationEmails(user, therapist, appointment);
      
      res.json({ message: 'Appointment cancelled successfully', appointment });
    } catch (error) {
      next(error);
    }
  }

  // Get available time slots for a therapist on a specific day
  static async getAvailableTimeSlots(req, res, next) {
    try {
      const { therapistId, date } = req.params;
      
      // Convert date string to Date object for start of day
      const startDate = new Date(date);
      startDate.setHours(0, 0, 0, 0);
      
      // End of day
      const endDate = new Date(startDate);
      endDate.setHours(23, 59, 59, 999);
      
      // Find all appointments for this therapist on this day
      const appointments = await Appointment.find({
        therapistId,
        appointmentDate: { $gte: startDate, $lte: endDate },
        status: { $ne: 'cancelled' }
      }).sort({ appointmentDate: 1 });
      
      // Assuming therapist works from 9 AM to 5 PM with 1-hour slots
      const workStartHour = 9;
      const workEndHour = 17;
      
      // Generate all possible time slots
      const timeSlots = [];
      for (let hour = workStartHour; hour < workEndHour; hour++) {
        const slotStart = new Date(startDate);
        slotStart.setHours(hour, 0, 0, 0);
        
        // Skip slots that are in the past
        if (slotStart < new Date()) continue;
        
        // Check if this slot conflicts with any existing appointment
        const isConflicting = appointments.some(appointment => {
          const appStart = new Date(appointment.appointmentDate);
          const appEnd = new Date(appointment.appointmentDate);
          appEnd.setMinutes(appEnd.getMinutes() + appointment.duration);
          
          const slotEnd = new Date(slotStart);
          slotEnd.setHours(slotEnd.getHours() + 1);
          
          return (
            (slotStart >= appStart && slotStart < appEnd) || // Slot starts during appointment
            (slotEnd > appStart && slotEnd <= appEnd) || // Slot ends during appointment
            (slotStart <= appStart && slotEnd >= appEnd) // Slot encompasses appointment
          );
        });
        
        timeSlots.push({
          startTime: slotStart,
          endTime: new Date(slotStart.getTime() + 60 * 60 * 1000), // 1 hour later
          available: !isConflicting
        });
      }
      
      res.json(timeSlots);
    } catch (error) {
      next(error);
    }
  }

  // Helper method to send confirmation emails
  static async _sendConfirmationEmails(user, therapist, appointment) {
    try {
      // Create email transporter
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
      
      const appointmentDate = appointment.appointmentDate.toLocaleString();
      const duration = appointment.duration;
      
      // Send email to user
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'Appointment Confirmation',
        text: `
          Dear ${user.username},
          
          Your appointment with ${therapist.name} has been confirmed.
          
          Details:
          Date and Time: ${appointmentDate}
          Duration: ${duration} minutes
          Meeting Link: ${appointment.meetingLink}
          
          If you need to reschedule or cancel, please do so at least 24 hours in advance.
          
          Best regards,
          MindEase Team
        `
      });
      
      // Send email to therapist
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: therapist.email,
        subject: 'New Appointment Scheduled',
        text: `
          Dear ${therapist.name},
          
          A new appointment has been scheduled with user ${user.username}.
          
          Details:
          Date and Time: ${appointmentDate}
          Duration: ${duration} minutes
          Meeting Link: ${appointment.meetingLink}
          
          Best regards,
          MindEase Team
        `
      });
    } catch (error) {
      console.error('Error sending confirmation emails:', error);
      // We don't throw the error as this is a secondary functionality
    }
  }

  // Helper method to send rescheduled emails
  static async _sendRescheduledEmails(user, therapist, appointment) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
      
      const appointmentDate = appointment.appointmentDate.toLocaleString();
      
      // Send email to user
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'Appointment Rescheduled',
        text: `
          Dear ${user.username},
          
          Your appointment with ${therapist.name} has been rescheduled.
          
          New details:
          Date and Time: ${appointmentDate}
          Duration: ${appointment.duration} minutes
          Meeting Link: ${appointment.meetingLink}
          
          Best regards,
          MindEase Team
        `
      });
      
      // Send email to therapist
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: therapist.email,
        subject: 'Appointment Rescheduled',
        text: `
          Dear ${therapist.name},
          
          Your appointment with user ${user.username} has been rescheduled.
          
          New details:
          Date and Time: ${appointmentDate}
          Duration: ${appointment.duration} minutes
          Meeting Link: ${appointment.meetingLink}
          
          Best regards,
          MindEase Team
        `
      });
    } catch (error) {
      console.error('Error sending rescheduled emails:', error);
    }
  }

  // Helper method to send cancellation emails
  static async _sendCancellationEmails(user, therapist, appointment) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT,
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });
      
      const appointmentDate = appointment.appointmentDate.toLocaleString();
      
      // Send email to user
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'Appointment Cancelled',
        text: `
          Dear ${user.username},
          
          Your appointment with ${therapist.name} scheduled for ${appointmentDate} has been cancelled.
          
          If you wish to schedule a new appointment, please visit our platform.
          
          Best regards,
          MindEase Team
        `
      });
      
      // Send email to therapist
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: therapist.email,
        subject: 'Appointment Cancelled',
        text: `
          Dear ${therapist.name},
          
          Your appointment with user ${user.username} scheduled for ${appointmentDate} has been cancelled.
          
          Best regards,
          MindEase Team
        `
      });
    } catch (error) {
      console.error('Error sending cancellation emails:', error);
    }
  }

  // Start an instant visit/meeting
  static async startInstantVisit(req, res, next) {
    try {
      const { userId, therapistId, therapistName, therapistEmail } = req.body;

      // Check if user exists
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      // Check if therapist exists
      const therapist = await Therapist.findById(therapistId);
      if (!therapist) {
        return res.status(404).json({ message: 'Therapist not found' });
      }

      // Generate meeting link (using Google Meet or similar service)
      const meetingId = `instant-${userId}-${therapistId}-${Date.now()}`;
      const meetingLink = await AppointmentController._generateMeetingLink(meetingId);

      // Create instant appointment record
      const instantAppointment = new Appointment({
        userId,
        therapistId,
        appointmentDate: new Date(),
        duration: 60, // Default 1 hour
        notes: 'Instant visit session',
        meetingLink,
        status: 'in-progress',
        type: 'instant'
      });

      await instantAppointment.save();

      // Send notifications to both user and therapist
      await AppointmentController._sendInstantVisitNotifications(
        user,
        therapist,
        meetingLink,
        instantAppointment
      );

      res.status(201).json({
        message: 'Instant visit started successfully',
        meetingLink,
        appointmentId: instantAppointment._id
      });

    } catch (error) {
      console.error('Error starting instant visit:', error);
      next(error);
    }
  }

  // Generate meeting link (Google Meet integration)
  static async _generateMeetingLink(meetingId) {

    try {
      // Import Google APIs and get the OAuth client from server
      const { google } = require('googleapis');
      const fs = require('fs');
      const path = require('path');

      // Load tokens from the config directory
      const TOKEN_PATH = path.join(__dirname, '../config/token.json');


      if (!fs.existsSync(TOKEN_PATH)) {
        console.log('Google tokens not found, using fallback');
        return `https://meet.google.com/new`;
      }

      const tokens = JSON.parse(fs.readFileSync(TOKEN_PATH));

      // Load Google credentials from secret.json
      const CREDENTIALS = require('../config/secret.json');

      // Create OAuth2 client
      const oAuth2Client = new google.auth.OAuth2(
        CREDENTIALS.web.client_id,
        CREDENTIALS.web.client_secret,
        'https://mindease-backend-production.up.railway.app/api/google-meet/oauth2callback'
      );

      oAuth2Client.setCredentials(tokens);

      const calendar = google.calendar({ version: 'v3', auth: oAuth2Client });

      const event = {
        summary: `Therapy Session - ${meetingId}`,
        description: 'Therapy session via MindEase',
        start: {
          dateTime: new Date().toISOString(),
          timeZone: 'UTC',
        },
        end: {
          dateTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(), // 1 hour
          timeZone: 'UTC',
        },
        conferenceData: {
          createRequest: {
            requestId: `therapy-${meetingId}-${Date.now()}`,
            conferenceSolutionKey: { type: 'hangoutsMeet' },
          },
        },
      };

      const response = await calendar.events.insert({
        calendarId: 'primary',
        resource: event,
        conferenceDataVersion: 1,
      });
      const meetLink = response.data.conferenceData.entryPoints.find(
        (entry) => entry.entryPointType === 'video'
      ).uri;

      console.log('Generated Google Meet link:', meetLink);
      return meetLink;

    } catch (error) {
      console.error('Error generating meeting link:', error.message);
      console.error('Full error:', error);
      // Fallback to a generic Google Meet link
      return `https://meet.google.com/new`;
    }
  }

  // Send instant visit notifications
  static async _sendInstantVisitNotifications(user, therapist, meetingLink, appointment) {
    try {
      const transporter = nodemailer.createTransporter({
        service: 'gmail',
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS
        }
      });

      // Email to user
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'Instant Visit Started - MindEase',
        text: `
          Hi ${user.username},

          Your instant visit with ${therapist.name} has been started!

          Meeting Link: ${meetingLink}

          Click the link above to join the video session.

          Best regards,
          MindEase Team
        `
      });

      // Email to therapist
      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: therapist.email,
        subject: 'New Instant Visit Request - MindEase',
        text: `
          Hi ${therapist.name},

          A user (${user.username}) has started an instant visit session with you.

          Meeting Link: ${meetingLink}

          Please join the video session as soon as possible.

          Best regards,
          MindEase Team
        `
      });

    } catch (error) {
      console.error('Error sending instant visit notifications:', error);
    }
  }

  // Update appointment status (for admin)
  static async updateAppointmentStatus(req, res, next) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const validStatuses = ['Scheduled', 'Completed', 'Cancelled'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          message: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
        });
      }

      const appointment = await Appointment.findByIdAndUpdate(
        id,
        { status },
        { new: true }
      ).populate('userId', 'username email')
       .populate('therapistId', 'name email');

      if (!appointment) {
        return res.status(404).json({ message: 'Appointment not found' });
      }

      res.json({
        message: `Appointment status updated to ${status}`,
        appointment
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AppointmentController;