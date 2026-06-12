export type Project = {
  title: string;
  desc: string;
};

export type BotKnowledge = {
  name: string;
  intro: string;
  stack: string;
  university: string;
  projects: Project[];
};

export const botKnowledge: BotKnowledge = {
  name: "AI Portfolio Assistant",
  intro: "Hi! I'm the AI assistant for this developer's portfolio.",
  stack: "MERN (MongoDB, Express.js, React, Node.js)",
  university: "Currently studying at BRAC University",
  projects: [
    {
      title: "DriveHub",
      desc: "A car marketplace & service platform built with the MERN stack.",
    },
    {
      title: "Missing Persons DApp",
      desc: "A decentralized app to manage missing person reports using React and Solidity.",
    },
    {
      title: "Personal Finance Manager",
      desc: "An AI-powered tool to track expenses and give financial insights.",
    },
  ],
};
