const axios = require('axios');

const API_BASE = 'http:// 192.168.2.102:3000/api';

const therapists = [
  {
    name: "Dr. Sarah Johnson",
    email: "sarah.johnson@mindease.com",
    phone: "+1-555-0101",
    specialty: "Anxiety & Depression",
    experience: 8,
    location: "New York, NY",
    coordinates: { type: "Point", coordinates: [-74.0060, 40.7128] },
    rating: 4.8,
    hourlyRate: 150,
    availability: [
      { day: "Monday", startTime: "09:00", endTime: "17:00" },
      { day: "Tuesday", startTime: "09:00", endTime: "17:00" },
      { day: "Wednesday", startTime: "09:00", endTime: "17:00" },
      { day: "Thursday", startTime: "09:00", endTime: "17:00" },
      { day: "Friday", startTime: "09:00", endTime: "15:00" }
    ],
    bio: "Specialized in cognitive behavioral therapy with 8 years of experience helping patients overcome anxiety and depression.",
    languages: ["English", "Spanish"],
    education: ["PhD Psychology - Harvard University", "MS Clinical Psychology - NYU"],
    certifications: ["Licensed Clinical Psychologist", "CBT Certified"]
  },
  {
    name: "Dr. Michael Chen",
    email: "michael.chen@mindease.com",
    phone: "+1-555-0102",
    specialty: "Trauma & PTSD",
    experience: 12,
    location: "Los Angeles, CA",
    coordinates: { type: "Point", coordinates: [-118.2437, 34.0522] },
    rating: 4.9,
    hourlyRate: 180,
    availability: [
      { day: "Monday", startTime: "10:00", endTime: "18:00" },
      { day: "Tuesday", startTime: "10:00", endTime: "18:00" },
      { day: "Wednesday", startTime: "10:00", endTime: "18:00" },
      { day: "Thursday", startTime: "10:00", endTime: "18:00" },
      { day: "Friday", startTime: "10:00", endTime: "16:00" }
    ],
    bio: "Expert in trauma therapy and PTSD treatment using EMDR and other evidence-based approaches.",
    languages: ["English", "Mandarin"],
    education: ["PhD Clinical Psychology - UCLA", "MS Psychology - Stanford"],
    certifications: ["Licensed Clinical Psychologist", "EMDR Certified", "Trauma Specialist"]
  },
  {
    name: "Dr. Emily Rodriguez",
    email: "emily.rodriguez@mindease.com",
    phone: "+1-555-0103",
    specialty: "Family & Couples Therapy",
    experience: 10,
    location: "Chicago, IL",
    coordinates: { type: "Point", coordinates: [-87.6298, 41.8781] },
    rating: 4.7,
    hourlyRate: 160,
    availability: [
      { day: "Monday", startTime: "08:00", endTime: "16:00" },
      { day: "Tuesday", startTime: "08:00", endTime: "16:00" },
      { day: "Wednesday", startTime: "08:00", endTime: "16:00" },
      { day: "Thursday", startTime: "08:00", endTime: "16:00" },
      { day: "Saturday", startTime: "09:00", endTime: "13:00" }
    ],
    bio: "Specializing in family dynamics and relationship counseling with a focus on communication and conflict resolution.",
    languages: ["English", "Spanish"],
    education: ["PhD Marriage & Family Therapy - Northwestern", "MS Psychology - DePaul"],
    certifications: ["Licensed Marriage & Family Therapist", "Gottman Method Certified"]
  },
  {
    name: "Dr. James Wilson",
    email: "james.wilson@mindease.com",
    phone: "+1-555-0104",
    specialty: "Addiction & Substance Abuse",
    experience: 15,
    location: "Houston, TX",
    coordinates: { type: "Point", coordinates: [-95.3698, 29.7604] },
    rating: 4.6,
    hourlyRate: 170,
    availability: [
      { day: "Monday", startTime: "09:00", endTime: "17:00" },
      { day: "Tuesday", startTime: "09:00", endTime: "17:00" },
      { day: "Wednesday", startTime: "09:00", endTime: "17:00" },
      { day: "Thursday", startTime: "09:00", endTime: "17:00" },
      { day: "Friday", startTime: "09:00", endTime: "17:00" }
    ],
    bio: "Experienced addiction counselor specializing in substance abuse recovery and relapse prevention.",
    languages: ["English"],
    education: ["PhD Addiction Psychology - UT Austin", "MS Clinical Psychology - Rice"],
    certifications: ["Licensed Addiction Counselor", "Certified Addiction Professional"]
  },
  {
    name: "Dr. Lisa Thompson",
    email: "lisa.thompson@mindease.com",
    phone: "+1-555-0105",
    specialty: "Child & Adolescent Therapy",
    experience: 9,
    location: "Phoenix, AZ",
    coordinates: { type: "Point", coordinates: [-112.0740, 33.4484] },
    rating: 4.8,
    hourlyRate: 140,
    availability: [
      { day: "Monday", startTime: "14:00", endTime: "20:00" },
      { day: "Tuesday", startTime: "14:00", endTime: "20:00" },
      { day: "Wednesday", startTime: "14:00", endTime: "20:00" },
      { day: "Thursday", startTime: "14:00", endTime: "20:00" },
      { day: "Saturday", startTime: "10:00", endTime: "16:00" }
    ],
    bio: "Dedicated to helping children and teenagers navigate emotional challenges through play therapy and cognitive techniques.",
    languages: ["English"],
    education: ["PhD Child Psychology - ASU", "MS Developmental Psychology - NAU"],
    certifications: ["Licensed Child Psychologist", "Play Therapy Certified"]
  }
];

async function addTherapists() {
  console.log('🚀 Starting to add therapists via API...');
  
  for (let i = 0; i < therapists.length; i++) {
    const therapist = therapists[i];
    try {
      console.log(`\n📝 Adding therapist ${i + 1}/${therapists.length}: ${therapist.name}`);
      
      const response = await axios.post(`${API_BASE}/therapists`, therapist, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      console.log(`✅ Successfully added: ${therapist.name} (ID: ${response.data._id})`);
    } catch (error) {
      console.error(`❌ Failed to add ${therapist.name}:`, error.response?.data || error.message);
    }
  }
  
  // Verify by fetching all therapists
  try {
    console.log('\n🔍 Fetching all therapists to verify...');
    const response = await axios.get(`${API_BASE}/therapists`);
    console.log(`✅ Total therapists in database: ${response.data.length}`);
    response.data.forEach((t, index) => {
      console.log(`${index + 1}. ${t.name} - ${t.specialty} (${t.location})`);
    });
  } catch (error) {
    console.error('❌ Failed to fetch therapists:', error.message);
  }
}

addTherapists();
